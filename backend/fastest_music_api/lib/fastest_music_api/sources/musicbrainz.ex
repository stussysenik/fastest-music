defmodule FastestMusicApi.Sources.MusicBrainz do
  @moduledoc """
  MusicBrainz + Cover Art Archive client — the secondary/fallback source.

  ## Why MusicBrainz?

  MusicBrainz is an open music encyclopedia with broader catalog coverage than iTunes.
  It catches edge cases (indie releases, international albums, classical music) that
  iTunes might miss. The Cover Art Archive provides artwork up to 1200px.

  ## Rate limiting

  MusicBrainz requires a User-Agent header and limits to 1 request/second.
  We use a simple token bucket approach: if we've made a request in the last second,
  we wait before sending another.
  """

  @behaviour FastestMusicApi.Sources.SourceBehaviour

  alias FastestMusicApi.Sources.CircuitBreaker

  @mb_base "https://musicbrainz.org/ws/2"
  @caa_base "https://coverartarchive.org"
  @user_agent "FastestMusicApi/1.0 (fastest-music-vol-2)"

  @impl true
  def search_albums(query, opts \\ []) do
    if CircuitBreaker.allow?(:musicbrainz) do
      do_search(query, opts)
    else
      {:error, :circuit_open}
    end
  end

  @impl true
  def get_album_artwork(artist, album) do
    if CircuitBreaker.allow?(:musicbrainz) do
      do_get_artwork(artist, album)
    else
      {:error, :circuit_open}
    end
  end

  # --- Private ---

  defp do_search(query, opts) do
    limit = Keyword.get(opts, :limit, 25)
    rate_limit_wait()

    url = "#{@mb_base}/release-group?" <> URI.encode_query(%{
      "query" => query,
      "type" => "album",
      "fmt" => "json",
      "limit" => limit
    })

    headers = [{"user-agent", @user_agent}, {"accept", "application/json"}]

    case Req.get(url, headers: headers, receive_timeout: 8_000) do
      {:ok, %{status: 200, body: %{"release-groups" => groups}}} ->
        CircuitBreaker.record_success(:musicbrainz)
        albums = Enum.map(groups, &normalize_release_group/1)
        {:ok, albums}

      {:ok, %{status: status}} ->
        CircuitBreaker.record_failure(:musicbrainz)
        {:error, {:http_error, status}}

      {:error, reason} ->
        CircuitBreaker.record_failure(:musicbrainz)
        {:error, reason}
    end
  end

  defp do_get_artwork(artist, album) do
    # First search for the release group to get its MBID
    rate_limit_wait()

    query = "\"#{album}\" AND artist:\"#{artist}\""
    url = "#{@mb_base}/release-group?" <> URI.encode_query(%{
      "query" => query,
      "type" => "album",
      "fmt" => "json",
      "limit" => 1
    })

    headers = [{"user-agent", @user_agent}, {"accept", "application/json"}]

    with {:ok, %{status: 200, body: %{"release-groups" => [first | _]}}} <-
           Req.get(url, headers: headers, receive_timeout: 8_000),
         mbid when is_binary(mbid) <- first["id"],
         {:ok, artwork_url} <- fetch_cover_art(mbid) do
      CircuitBreaker.record_success(:musicbrainz)
      {:ok, artwork_url}
    else
      {:ok, %{status: 200, body: %{"release-groups" => []}}} ->
        CircuitBreaker.record_success(:musicbrainz)
        {:error, :not_found}

      {:error, reason} ->
        CircuitBreaker.record_failure(:musicbrainz)
        {:error, reason}

      _ ->
        {:error, :not_found}
    end
  end

  defp fetch_cover_art(mbid) do
    url = "#{@caa_base}/release-group/#{mbid}"
    headers = [{"user-agent", @user_agent}, {"accept", "application/json"}]

    case Req.get(url, headers: headers, receive_timeout: 8_000, redirect: true) do
      {:ok, %{status: 200, body: %{"images" => [first | _]}}} ->
        thumbnail_url = get_in(first, ["thumbnails", "500"]) ||
                        get_in(first, ["thumbnails", "large"]) ||
                        first["image"]

        if thumbnail_url, do: {:ok, thumbnail_url}, else: {:error, :no_artwork}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp normalize_release_group(group) do
    artist_name = case group["artist-credit"] do
      [%{"name" => name} | _] -> name
      _ -> ""
    end

    %{
      "id" => "mb:#{group["id"] || ""}",
      "title" => group["title"] || "",
      "artistName" => artist_name,
      "artworkUrl" => nil,
      "trackCount" => 0,
      "releaseDate" => group["first-release-date"] || "",
      "genreNames" => []
    }
  end

  # Simple rate limiter: wait if we're within 1 second of last request
  defp rate_limit_wait do
    case Process.get(:mb_last_request) do
      nil -> :ok
      last ->
        elapsed = System.monotonic_time(:millisecond) - last
        if elapsed < 1000, do: Process.sleep(1000 - elapsed)
    end
    Process.put(:mb_last_request, System.monotonic_time(:millisecond))
  end
end
