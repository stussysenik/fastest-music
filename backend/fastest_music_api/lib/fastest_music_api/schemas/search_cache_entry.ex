defmodule FastestMusicApi.Schemas.SearchCacheEntry do
  @moduledoc """
  Ecto schema for the persistent search result cache.

  Stores full search result JSON so repeat queries can be served from Postgres
  instead of re-querying external APIs. Expires after 1 hour.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "search_cache" do
    field :query_normalized, :string
    field :result_type, :string
    field :filters_hash, :string, default: ""
    field :results_json, :map
    field :expires_at, :utc_datetime

    timestamps()
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:query_normalized, :result_type, :filters_hash, :results_json, :expires_at])
    |> validate_required([:query_normalized, :result_type, :results_json])
    |> unique_constraint([:query_normalized, :result_type, :filters_hash])
  end
end
