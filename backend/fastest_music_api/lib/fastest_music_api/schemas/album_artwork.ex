defmodule FastestMusicApi.Schemas.AlbumArtwork do
  @moduledoc """
  Ecto schema for the persistent artwork URL cache.

  Keyed by normalized {artist, album} so lookups are case-insensitive and
  whitespace-tolerant. URLs come from iTunes, MusicBrainz Cover Art Archive, etc.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "album_artworks" do
    field :artist_name_normalized, :string
    field :album_title_normalized, :string
    field :artwork_url, :string
    field :source, :string
    field :width, :integer
    field :height, :integer
    field :expires_at, :utc_datetime

    timestamps()
  end

  def changeset(artwork, attrs) do
    artwork
    |> cast(attrs, [:artist_name_normalized, :album_title_normalized, :artwork_url, :source, :width, :height, :expires_at])
    |> validate_required([:artist_name_normalized, :album_title_normalized, :artwork_url, :source])
    |> unique_constraint([:artist_name_normalized, :album_title_normalized])
  end
end
