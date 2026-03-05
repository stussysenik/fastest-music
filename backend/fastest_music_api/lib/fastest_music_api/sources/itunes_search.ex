defmodule FastestMusicApi.Sources.ItunesSearch do
  @moduledoc """
  iTunes Search API client — the primary data source.

  ## Why iTunes Search?

  The iTunes Search API serves data from the same Apple Music CDN that MusicKit uses.
  This means artwork URLs, album metadata, and search results are consistent with
  what the Flutter app already shows via MusicKit — no visual inconsistencies.

  It's also free, requires no authentication, and has generous rate limits.

  ## Artwork resolution trick

  iTunes returns artwork URLs with `100x100` in the path (e.g., `.../100x100bb.jpg`).
  We replace that with `600x600` to get full-resolution covers from the same CDN.
  """

  @behaviour FastestMusicApi.Sources.SourceBehaviour

  alias FastestMusicApi.Sources.CircuitBreaker

  @base_url "https://itunes.apple.com"

  @impl true
  def search_albums(query, opts \\ []) do
    if CircuitBreaker.allow?(:itunes) do
      do_search(query, opts)
    else
      {:error, :circuit_open}
    end
  end

  @impl true
  def get_album_artwork(artist, album) do
    if CircuitBreaker.allow?(:itunes) do
      do_get_artwork(artist, album)
    else
      {:error, :circuit_open}
    end
  end

  # --- Private ---

  defp do_search(query, opts) do
    limit = Keyword.get(opts, :limit, 25)

    url = "#{@base_url}/search?" <> URI.encode_query(%{
      "term" => query,
      "media" => "music",
      "entity" => "album",
      "limit" => limit
    })

    case Req.get(url, receive_timeout: 5_000) do
      {:ok, %{status: 200, body: body}} ->
        case decode_body(body) do
          %{"results" => results} ->
            CircuitBreaker.record_success(:itunes)
            albums = Enum.map(results, &normalize_album/1)
            {:ok, albums}

          _ ->
            CircuitBreaker.record_failure(:itunes)
            {:error, :invalid_response}
        end

      {:ok, %{status: status}} ->
        CircuitBreaker.record_failure(:itunes)
        {:error, {:http_error, status}}

      {:error, reason} ->
        CircuitBreaker.record_failure(:itunes)
        {:error, reason}
    end
  end

  defp do_get_artwork(artist, album) do
    query = "#{artist} #{album}"

    url = "#{@base_url}/search?" <> URI.encode_query(%{
      "term" => query,
      "media" => "music",
      "entity" => "album",
      "limit" => 1
    })

    case Req.get(url, receive_timeout: 5_000) do
      {:ok, %{status: 200, body: body}} ->
        case decode_body(body) do
          %{"results" => [first | _]} ->
            CircuitBreaker.record_success(:itunes)
            artwork_url = upscale_artwork(first["artworkUrl100"] || first["artworkUrl60"] || "")
            if artwork_url != "", do: {:ok, artwork_url}, else: {:error, :no_artwork}

          %{"results" => []} ->
            CircuitBreaker.record_success(:itunes)
            {:error, :not_found}

          _ ->
            CircuitBreaker.record_failure(:itunes)
            {:error, :invalid_response}
        end

      {:ok, %{status: status}} ->
        CircuitBreaker.record_failure(:itunes)
        {:error, {:http_error, status}}

      {:error, reason} ->
        CircuitBreaker.record_failure(:itunes)
        {:error, reason}
    end
  end

  # iTunes API returns text/javascript content-type, so Req doesn't auto-decode JSON.
  # We handle both cases: already-decoded map (if Req does decode) or raw string.
  defp decode_body(body) when is_map(body), do: body
  defp decode_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> decoded
      {:error, _} -> nil
    end
  end
  defp decode_body(_), do: nil

  defp normalize_album(itunes_result) do
    artwork_url = upscale_artwork(itunes_result["artworkUrl100"] || itunes_result["artworkUrl60"] || "")

    %{
      "id" => to_string(itunes_result["collectionId"] || ""),
      "title" => itunes_result["collectionName"] || "",
      "artistName" => itunes_result["artistName"] || "",
      "artworkUrl" => artwork_url,
      "trackCount" => itunes_result["trackCount"] || 0,
      "releaseDate" => itunes_result["releaseDate"] || "",
      "genreNames" => [itunes_result["primaryGenreName"] || ""] |> Enum.reject(&(&1 == ""))
    }
  end

  @doc """
  Replace the default 100x100 artwork size with 600x600 for high-res covers.
  The Apple Music CDN supports arbitrary sizes in the URL path.
  """
  def upscale_artwork(url) when is_binary(url) do
    url
    |> String.replace("100x100", "600x600")
    |> String.replace("60x60", "600x600")
  end
  def upscale_artwork(_), do: ""
end
