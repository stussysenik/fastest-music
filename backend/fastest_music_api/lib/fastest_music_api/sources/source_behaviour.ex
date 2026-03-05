defmodule FastestMusicApi.Sources.SourceBehaviour do
  @moduledoc """
  Behaviour (interface) that all music API source clients must implement.

  ## Why use a Behaviour?

  Behaviours in Elixir are like interfaces in OOP — they define a contract that
  implementing modules must follow. This lets ArtworkResolver and SearchEngine
  work with any source interchangeably, making it trivial to add new sources
  (Spotify, Deezer, etc.) without changing the resolver logic.
  """

  @type search_opts :: [
    limit: pos_integer(),
    type: String.t()
  ]

  @callback search_albums(query :: String.t(), opts :: search_opts()) ::
    {:ok, [map()]} | {:error, term()}

  @callback get_album_artwork(artist :: String.t(), album :: String.t()) ::
    {:ok, String.t()} | {:error, term()}
end
