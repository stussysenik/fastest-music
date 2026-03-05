defmodule FastestMusicApi.Repo.Migrations.CreateSearchCache do
  use Ecto.Migration

  def change do
    create table(:search_cache) do
      add :query_normalized, :string, null: false
      add :result_type, :string, null: false
      add :filters_hash, :string, null: false, default: ""
      add :results_json, :map, null: false
      add :expires_at, :utc_datetime

      timestamps()
    end

    create unique_index(:search_cache, [:query_normalized, :result_type, :filters_hash])
  end
end
