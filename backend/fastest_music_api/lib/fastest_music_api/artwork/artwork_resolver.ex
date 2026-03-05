defmodule FastestMusicApi.Artwork.ArtworkResolver do
  @moduledoc """
  The heart of the system — L1/L2/L3 cascade for artwork resolution.

  ## Cache hierarchy (educational)

  This implements a classic multi-tier caching pattern:

  1. **L1 — ETS** (~1μs): In-memory, fastest possible. Lost on restart.
  2. **L2 — Postgres** (~5ms): Persistent, survives restarts. Warm L1 from here.
  3. **L3 — External APIs** (~200ms+): iTunes Search, then MusicBrainz fallback.

  Each tier writes back to all faster tiers on hit, so subsequent requests
  are always served from the fastest available cache.

  If all sources fail, we serve stale data from L2 (ignoring expiry).
  If nothing exists at all, we return nil and the Flutter app falls back to MusicKit.
  """

  alias FastestMusicApi.Cache.EtsCache
  alias FastestMusicApi.Repo
  alias FastestMusicApi.Schemas.AlbumArtwork
  alias FastestMusicApi.Sources.ItunesSearch
  alias FastestMusicApi.Sources.MusicBrainz

  import Ecto.Query

  @doc """
  Resolve artwork URL for an artist + album combination.
  Returns `{:ok, url}` or `{:error, :not_found}`.
  """
  def get_artwork(artist, album) do
    artist_norm = normalize(artist)
    album_norm = normalize(album)

    with :miss <- check_l1(artist_norm, album_norm),
         :miss <- check_l2(artist_norm, album_norm),
         {:error, _} <- check_l3_itunes(artist, album, artist_norm, album_norm),
         {:error, _} <- check_l3_musicbrainz(artist, album, artist_norm, album_norm),
         :miss <- check_l2_stale(artist_norm, album_norm) do
      {:error, :not_found}
    end
  end

  # --- L1: ETS Cache ---
  defp check_l1(artist_norm, album_norm) do
    case EtsCache.get_artwork(artist_norm, album_norm) do
      {:hit, url} -> {:ok, url}
      :miss -> :miss
    end
  end

  # --- L2: Postgres ---
  defp check_l2(artist_norm, album_norm) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    case Repo.one(
      from(a in AlbumArtwork,
        where: a.artist_name_normalized == ^artist_norm and
               a.album_title_normalized == ^album_norm and
               (a.expires_at > ^now or is_nil(a.expires_at)),
        select: a.artwork_url,
        limit: 1
      )
    ) do
      nil -> :miss
      url ->
        # Write back to L1
        EtsCache.put_artwork(artist_norm, album_norm, url)
        {:ok, url}
    end
  end

  # --- L3: iTunes Search (primary) ---
  defp check_l3_itunes(artist, album, artist_norm, album_norm) do
    case ItunesSearch.get_album_artwork(artist, album) do
      {:ok, url} ->
        persist_artwork(artist_norm, album_norm, url, "itunes")
        {:ok, url}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # --- L3: MusicBrainz (fallback) ---
  defp check_l3_musicbrainz(artist, album, artist_norm, album_norm) do
    case MusicBrainz.get_album_artwork(artist, album) do
      {:ok, url} ->
        persist_artwork(artist_norm, album_norm, url, "musicbrainz")
        {:ok, url}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # --- Stale L2: Serve expired data as last resort ---
  defp check_l2_stale(artist_norm, album_norm) do
    case Repo.one(
      from(a in AlbumArtwork,
        where: a.artist_name_normalized == ^artist_norm and
               a.album_title_normalized == ^album_norm,
        select: a.artwork_url,
        order_by: [desc: a.updated_at],
        limit: 1
      )
    ) do
      nil -> :miss
      url ->
        EtsCache.put_artwork(artist_norm, album_norm, url)
        {:ok, url}
    end
  end

  # --- Persistence: Write to L1 + L2 ---
  defp persist_artwork(artist_norm, album_norm, url, source) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    expires_at = DateTime.add(now, 30, :day)

    # Write to L1
    EtsCache.put_artwork(artist_norm, album_norm, url)

    # Write to L2 (upsert)
    Repo.insert(
      %AlbumArtwork{
        artist_name_normalized: artist_norm,
        album_title_normalized: album_norm,
        artwork_url: url,
        source: source,
        width: 600,
        height: 600,
        expires_at: expires_at
      },
      on_conflict: [set: [artwork_url: url, source: source, expires_at: expires_at, updated_at: now]],
      conflict_target: [:artist_name_normalized, :album_title_normalized]
    )
  end

  @doc "Normalize a string for case-insensitive, whitespace-tolerant matching."
  def normalize(str) when is_binary(str) do
    str
    |> String.downcase()
    |> String.replace(~r/[^\w\s]/u, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
  def normalize(_), do: ""
end
