defmodule FastestMusicApi.Cache.CacheWarmer do
  @moduledoc """
  Warms ETS (L1) cache from Postgres (L2) on application boot.

  ## Why warm the cache?

  After a server restart, ETS tables are empty (they're in-memory only).
  Without warming, every request would be a cache miss and hit Postgres.
  This module loads the most recent non-expired entries into ETS at startup
  so we get microsecond reads immediately.

  Loads up to 100K artworks and 10K search entries — typically completes in 1-3s.
  """
  use GenServer
  require Logger

  alias FastestMusicApi.Repo
  alias FastestMusicApi.Schemas.AlbumArtwork
  alias FastestMusicApi.Schemas.SearchCacheEntry
  alias FastestMusicApi.Cache.EtsCache

  import Ecto.Query

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    # Warm cache asynchronously so it doesn't block app startup
    Task.start(fn -> warm() end)
    {:ok, %{}}
  end

  defp warm do
    now = DateTime.utc_now()

    artwork_count = warm_artworks(now)
    search_count = warm_searches(now)

    Logger.info("Cache warmed: #{artwork_count} artworks, #{search_count} searches loaded into ETS")
  rescue
    error ->
      Logger.warning("Cache warming failed (non-fatal): #{inspect(error)}")
  end

  defp warm_artworks(now) do
    artworks =
      from(a in AlbumArtwork,
        where: a.expires_at > ^now or is_nil(a.expires_at),
        select: {a.artist_name_normalized, a.album_title_normalized, a.artwork_url},
        limit: 100_000
      )
      |> Repo.all()

    EtsCache.bulk_put_artworks(artworks)
    length(artworks)
  end

  defp warm_searches(now) do
    searches =
      from(s in SearchCacheEntry,
        where: s.expires_at > ^now or is_nil(s.expires_at),
        select: {s.query_normalized, s.result_type, s.filters_hash, s.results_json},
        limit: 10_000
      )
      |> Repo.all()

    EtsCache.bulk_put_searches(searches)
    length(searches)
  end
end
