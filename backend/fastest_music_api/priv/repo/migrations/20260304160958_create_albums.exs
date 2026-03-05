defmodule FastestMusicApi.Repo.Migrations.CreateAlbums do
  use Ecto.Migration

  def change do
    create table(:albums) do
      add :mbid, :string
      add :apple_id, :string
      add :title, :string, null: false
      add :artist_name, :string, null: false
      add :track_count, :integer, default: 0
      add :release_date, :string
      add :genre_names, {:array, :string}, default: []

      timestamps()
    end

    create index(:albums, [:apple_id])
    create index(:albums, [:mbid])
    create index(:albums, [:artist_name, :title])
  end
end
