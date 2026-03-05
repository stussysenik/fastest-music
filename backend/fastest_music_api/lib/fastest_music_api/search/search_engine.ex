defmodule FastestMusicApi.Search.SearchEngine do
  @moduledoc """
  Fan-out search engine that queries multiple sources concurrently.

  ## How it works (educational)

  1. Check L1 (ETS) and L2 (Postgres) caches first
  2. If cache miss, fire requests to iTunes and MusicBrainz in parallel using Task.async
  3. Wait up to 4 seconds for both to respond (Task.await_many)
  4. Merge results: deduplicate by normalized {artist, title}, prefer iTunes metadata
  5. Cache merged results in L1 + L2

  This means:
  - Cached queries respond in <2ms
  - Cold queries get results from whichever source responds first
  - We get broader catalog coverage by merging both sources
  """

  alias FastestMusicApi.Artwork.ArtworkResolver
  alias FastestMusicApi.Cache.EtsCache
  alias FastestMusicApi.Repo
  alias FastestMusicApi.Schemas.SearchCacheEntry
  alias FastestMusicApi.Sources.ItunesSearch
  alias FastestMusicApi.Sources.MusicBrainz
  alias FastestMusicApi.Search.SearchFilters

  import Ecto.Query

  @doc """
  Search for albums across all sources.
  Returns `{:ok, results, cached: boolean}`.
  """
  def search(query, opts \\ []) do
    query_norm = normalize_query(query)
    type = Keyword.get(opts, :type, "album")
    genre = Keyword.get(opts, :genre, nil)
    year_from = Keyword.get(opts, :year_from, nil)
    year_to = Keyword.get(opts, :year_to, nil)
    filters_hash = SearchFilters.hash_filters(genre, year_from, year_to)

    # L1: ETS check
    case EtsCache.get_search(query_norm, type, filters_hash) do
      {:hit, results} ->
        {:ok, results, true}

      :miss ->
        # L2: Postgres check
        case check_l2_search(query_norm, type, filters_hash) do
          {:ok, results} ->
            {:ok, results, true}

          :miss ->
            # L3: Fan-out to sources
            results = fan_out_search(query, opts)
            filtered = SearchFilters.apply_filters(results, genre, year_from, year_to)

            # Cache unfiltered results for reuse with different filters
            cache_results(query_norm, type, "", results)
            # Also cache filtered results
            if filters_hash != "" do
              cache_results(query_norm, type, filters_hash, filtered)
            end

            {:ok, filtered, false}
        end
    end
  end

  # --- Private ---

  defp fan_out_search(query, opts) do
    # Fire both sources concurrently
    itunes_task = Task.async(fn ->
      case ItunesSearch.search_albums(query, opts) do
        {:ok, results} -> results
        _ -> []
      end
    end)

    mb_task = Task.async(fn ->
      case MusicBrainz.search_albums(query, opts) do
        {:ok, results} -> results
        _ -> []
      end
    end)

    # Wait up to 4 seconds for both
    results = Task.await_many([itunes_task, mb_task], 4_000)
    [itunes_results, mb_results] = results

    merged = merge_results(itunes_results, mb_results)
    enrich_artwork(merged)
  rescue
    # If tasks time out, return whatever we have
    _ -> []
  end

  defp merge_results(itunes_results, mb_results) do
    # Index iTunes results by normalized {artist, title} for dedup
    itunes_index = Map.new(itunes_results, fn album ->
      key = {normalize_query(album["artistName"] || ""), normalize_query(album["title"] || "")}
      {key, album}
    end)

    # Add MusicBrainz results that iTunes doesn't have
    extra_from_mb = Enum.reject(mb_results, fn album ->
      key = {normalize_query(album["artistName"] || ""), normalize_query(album["title"] || "")}
      Map.has_key?(itunes_index, key)
    end)

    # iTunes results first (preferred), then unique MusicBrainz additions
    itunes_results ++ extra_from_mb
  end

  # Concurrently resolve artwork for albums missing artworkUrl (e.g. MusicBrainz results).
  # Uses the ArtworkResolver L1/L2/L3 cascade — cached albums resolve in microseconds,
  # new ones hit iTunes/CAA in parallel. 3s timeout keeps search responsive.
  defp enrich_artwork(albums) do
    {_with_art, without_art} = Enum.split_with(albums, fn a ->
      url = a["artworkUrl"]
      is_binary(url) and url != ""
    end)

    if without_art == [] do
      albums
    else
      resolved = without_art
      |> Task.async_stream(
        fn album ->
          artist = album["artistName"] || ""
          title = album["title"] || ""
          case ArtworkResolver.get_artwork(artist, title) do
            {:ok, url} -> Map.put(album, "artworkUrl", url)
            _ -> album
          end
        end,
        max_concurrency: 10,
        timeout: 3_000,
        on_timeout: :kill_task
      )
      |> Enum.map(fn
        {:ok, album} -> album
        {:exit, _} -> nil
      end)
      |> Enum.reject(&is_nil/1)

      # Rebuild in original order: iterate original list, swap in resolved versions
      resolved_index = Map.new(resolved, fn a -> {{a["artistName"], a["title"]}, a} end)

      Enum.map(albums, fn album ->
        key = {album["artistName"], album["title"]}
        case Map.fetch(resolved_index, key) do
          {:ok, enriched} -> enriched
          :error -> album
        end
      end)
    end
  end

  defp check_l2_search(query_norm, type, filters_hash) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    case Repo.one(
      from(s in SearchCacheEntry,
        where: s.query_normalized == ^query_norm and
               s.result_type == ^type and
               s.filters_hash == ^filters_hash and
               (s.expires_at > ^now or is_nil(s.expires_at)),
        select: s.results_json,
        limit: 1
      )
    ) do
      nil -> :miss
      %{"results" => results} ->
        # Write back to L1
        EtsCache.put_search(query_norm, type, results, filters_hash)
        {:ok, results}
      _ -> :miss
    end
  end

  defp cache_results(query_norm, type, filters_hash, results) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    expires_at = DateTime.add(now, 3600, :second)

    # Write to L1
    EtsCache.put_search(query_norm, type, results, filters_hash)

    # Write to L2 (upsert)
    Repo.insert(
      %SearchCacheEntry{
        query_normalized: query_norm,
        result_type: type,
        filters_hash: filters_hash,
        results_json: %{"results" => results},
        expires_at: expires_at
      },
      on_conflict: [set: [results_json: %{"results" => results}, expires_at: expires_at, updated_at: now]],
      conflict_target: [:query_normalized, :result_type, :filters_hash]
    )
  end

  defp normalize_query(str) when is_binary(str) do
    str
    |> String.downcase()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
  defp normalize_query(_), do: ""
end
