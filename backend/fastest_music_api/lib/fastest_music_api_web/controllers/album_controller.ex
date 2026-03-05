defmodule FastestMusicApiWeb.AlbumController do
  @moduledoc """
  Handles album detail and artwork requests.

  GET /api/albums/:id               — album details (from cache)
  GET /api/albums/by-name/artwork?artist=Radiohead&album=OK+Computer — artwork by name
  """
  use FastestMusicApiWeb, :controller

  alias FastestMusicApi.Repo
  alias FastestMusicApi.Schemas.Album
  alias FastestMusicApi.Artwork.ArtworkResolver

  def show(conn, %{"id" => id}) do
    case Repo.get(Album, id) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{"error" => "Album not found"})

      album ->
        json(conn, %{
          "id" => to_string(album.id),
          "title" => album.title,
          "artistName" => album.artist_name,
          "trackCount" => album.track_count,
          "releaseDate" => album.release_date,
          "genreNames" => album.genre_names
        })
    end
  end

  def artwork_by_name(conn, params) do
    artist = params["artist"] || ""
    album = params["album"] || ""

    if artist == "" or album == "" do
      conn
      |> put_status(400)
      |> json(%{"error" => "Missing required parameters: artist, album"})
    else
      case ArtworkResolver.get_artwork(artist, album) do
        {:ok, url} ->
          json(conn, %{"artworkUrl" => url, "artist" => artist, "album" => album})

        {:error, :not_found} ->
          conn
          |> put_status(404)
          |> json(%{"error" => "Artwork not found", "artist" => artist, "album" => album})
      end
    end
  end
end
