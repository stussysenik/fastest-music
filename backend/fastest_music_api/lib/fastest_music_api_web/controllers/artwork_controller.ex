defmodule FastestMusicApiWeb.ArtworkController do
  @moduledoc """
  Handles batch artwork resolution.

  POST /api/artwork/batch
  Body: {"albums": [{"artist": "Radiohead", "title": "OK Computer"}, ...]}

  Resolves up to 50 artworks concurrently, returning URLs from cache or
  fetching from external APIs as needed.
  """
  use FastestMusicApiWeb, :controller

  alias FastestMusicApi.Artwork.BatchResolver

  def batch(conn, %{"albums" => albums}) when is_list(albums) do
    results = BatchResolver.resolve_batch(albums)

    json(conn, %{
      "results" => results,
      "count" => length(results)
    })
  end

  def batch(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{"error" => "Missing required field: albums (array of {artist, title})"})
  end
end
