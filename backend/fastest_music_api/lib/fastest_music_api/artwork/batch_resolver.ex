defmodule FastestMusicApi.Artwork.BatchResolver do
  @moduledoc """
  Resolves artwork for multiple albums concurrently.

  ## Why batch?

  When the Flutter app loads a search result with 25 albums, making 25 sequential
  artwork requests would take ~25 * 200ms = 5 seconds. By using Task.async_stream
  with max_concurrency: 20, we resolve them all in parallel — typically under 500ms
  for a full page of results.

  Each individual resolution goes through the full L1/L2/L3 cascade,
  so cached albums resolve in microseconds while new ones hit APIs in parallel.
  """

  alias FastestMusicApi.Artwork.ArtworkResolver

  @max_concurrency 20
  @max_batch_size 50

  @doc """
  Resolve artworks for a list of `%{artist: "...", title: "..."}` maps.
  Returns a list of `%{artist: "...", title: "...", artworkUrl: "..." | nil}`.
  """
  def resolve_batch(albums) when is_list(albums) do
    albums
    |> Enum.take(@max_batch_size)
    |> Task.async_stream(
      fn %{"artist" => artist, "title" => title} ->
        case ArtworkResolver.get_artwork(artist, title) do
          {:ok, url} -> %{"artist" => artist, "title" => title, "artworkUrl" => url}
          _ -> %{"artist" => artist, "title" => title, "artworkUrl" => nil}
        end
      end,
      max_concurrency: @max_concurrency,
      timeout: 10_000,
      on_timeout: :kill_task
    )
    |> Enum.map(fn
      {:ok, result} -> result
      {:exit, _} -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end
end
