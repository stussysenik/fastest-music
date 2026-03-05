defmodule FastestMusicApiWeb.SearchController do
  @moduledoc """
  Handles search requests.

  GET /api/search?q=radiohead&type=album&genre=rock&year_from=1990&year_to=2005

  Returns JSON that matches the Flutter app's existing Freezed model field names,
  so Album.fromJson() works without any client-side changes.
  """
  use FastestMusicApiWeb, :controller

  alias FastestMusicApi.Search.SearchEngine

  def index(conn, params) do
    query = params["q"] || ""

    if String.trim(query) == "" do
      conn
      |> put_status(400)
      |> json(%{"error" => "Missing required parameter: q"})
    else
      opts = [
        type: params["type"] || "album",
        genre: params["genre"],
        year_from: params["year_from"],
        year_to: params["year_to"]
      ]

      {:ok, results, cached} = SearchEngine.search(query, opts)

      json(conn, %{
        "results" => results,
        "cached" => cached,
        "count" => length(results)
      })
    end
  end
end
