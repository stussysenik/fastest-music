defmodule FastestMusicApi.Schemas.Album do
  @moduledoc """
  Ecto schema for the persistent album metadata cache.

  Stores album info from multiple sources (iTunes, MusicBrainz) so we can serve
  repeat queries from Postgres (~5ms) instead of hitting external APIs (~200ms+).
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "albums" do
    field :mbid, :string
    field :apple_id, :string
    field :title, :string
    field :artist_name, :string
    field :track_count, :integer, default: 0
    field :release_date, :string
    field :genre_names, {:array, :string}, default: []

    timestamps()
  end

  def changeset(album, attrs) do
    album
    |> cast(attrs, [:mbid, :apple_id, :title, :artist_name, :track_count, :release_date, :genre_names])
    |> validate_required([:title, :artist_name])
  end
end
