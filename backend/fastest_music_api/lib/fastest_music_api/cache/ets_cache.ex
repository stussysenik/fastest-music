defmodule FastestMusicApi.Cache.EtsCache do
  @moduledoc """
  GenServer owning two named ETS tables for microsecond-fast reads.

  ## How ETS caching works (educational)

  ETS (Erlang Term Storage) is an in-memory key-value store built into the BEAM VM.
  Reads take ~1 microsecond — roughly 5000x faster than a Postgres query.
  We use it as L1 cache: check ETS first, fall back to Postgres (L2), then APIs (L3).

  This GenServer owns the ETS tables (they're destroyed if the owner process dies,
  but our supervision tree will restart it and the CacheWarmer repopulates from Postgres).

  TTLs:
  - Artwork: 30 days (album covers rarely change)
  - Search: 1 hour (catalog changes more frequently)
  """
  use GenServer

  @artwork_table :artwork_cache
  @search_table :search_cache
  @artwork_ttl_seconds 30 * 24 * 3600  # 30 days
  @search_ttl_seconds 3600             # 1 hour
  @cleanup_interval_ms 10 * 60 * 1000  # 10 minutes

  # --- Public API ---

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc "Get cached artwork URL by normalized {artist, album}."
  def get_artwork(artist_norm, album_norm) do
    case :ets.lookup(@artwork_table, {artist_norm, album_norm}) do
      [{_key, url, inserted_at}] ->
        if expired?(inserted_at, @artwork_ttl_seconds), do: :miss, else: {:hit, url}

      [] ->
        :miss
    end
  rescue
    ArgumentError -> :miss
  end

  @doc "Store artwork URL in ETS."
  def put_artwork(artist_norm, album_norm, url) do
    :ets.insert(@artwork_table, {{artist_norm, album_norm}, url, System.system_time(:second)})
    :ok
  rescue
    ArgumentError -> :ok
  end

  @doc "Get cached search results."
  def get_search(query_norm, type, filters_hash \\ "") do
    case :ets.lookup(@search_table, {query_norm, type, filters_hash}) do
      [{_key, results, inserted_at}] ->
        if expired?(inserted_at, @search_ttl_seconds), do: :miss, else: {:hit, results}

      [] ->
        :miss
    end
  rescue
    ArgumentError -> :miss
  end

  @doc "Store search results in ETS."
  def put_search(query_norm, type, results, filters_hash \\ "") do
    :ets.insert(@search_table, {{query_norm, type, filters_hash}, results, System.system_time(:second)})
    :ok
  rescue
    ArgumentError -> :ok
  end

  @doc "Bulk insert artworks (used by CacheWarmer on boot)."
  def bulk_put_artworks(entries) do
    now = System.system_time(:second)
    objects = Enum.map(entries, fn {artist, album, url} ->
      {{artist, album}, url, now}
    end)
    :ets.insert(@artwork_table, objects)
    :ok
  rescue
    ArgumentError -> :ok
  end

  @doc "Bulk insert search entries (used by CacheWarmer on boot)."
  def bulk_put_searches(entries) do
    now = System.system_time(:second)
    objects = Enum.map(entries, fn {query, type, filters_hash, results} ->
      {{query, type, filters_hash}, results, now}
    end)
    :ets.insert(@search_table, objects)
    :ok
  rescue
    ArgumentError -> :ok
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(_) do
    :ets.new(@artwork_table, [:named_table, :set, :public, read_concurrency: true])
    :ets.new(@search_table, [:named_table, :set, :public, read_concurrency: true])
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired(@artwork_table, @artwork_ttl_seconds)
    cleanup_expired(@search_table, @search_ttl_seconds)
    schedule_cleanup()
    {:noreply, state}
  end

  # --- Private ---

  defp expired?(inserted_at, ttl_seconds) do
    System.system_time(:second) - inserted_at > ttl_seconds
  end

  defp cleanup_expired(table, ttl_seconds) do
    cutoff = System.system_time(:second) - ttl_seconds
    # Match entries where inserted_at < cutoff and delete them
    :ets.select_delete(table, [{{:_, :_, :"$1"}, [{:<, :"$1", cutoff}], [true]}])
  rescue
    ArgumentError -> :ok
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval_ms)
  end
end
