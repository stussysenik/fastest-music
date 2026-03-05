defmodule FastestMusicApi.Repo.Migrations.CreateAlbumArtworks do
  use Ecto.Migration

  def change do
    create table(:album_artworks) do
      add :artist_name_normalized, :string, null: false
      add :album_title_normalized, :string, null: false
      add :artwork_url, :text, null: false
      add :source, :string, null: false
      add :width, :integer
      add :height, :integer
      add :expires_at, :utc_datetime

      timestamps()
    end

    create unique_index(:album_artworks, [:artist_name_normalized, :album_title_normalized])
  end
end
