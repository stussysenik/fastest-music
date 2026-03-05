defmodule FastestMusicApi.Application do
  @moduledoc """
  OTP Application supervision tree.

  ## Supervision strategy (educational)

  OTP's "let it crash" philosophy means we don't try to handle every error —
  instead, we let processes crash and have supervisors restart them.

  The :one_for_one strategy means if one child crashes, only that child restarts.
  Children start in order, so Repo (Postgres) starts before EtsCache,
  and EtsCache starts before CacheWarmer (which needs both Repo and ETS).
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Infrastructure
      FastestMusicApiWeb.Telemetry,
      FastestMusicApi.Repo,
      {DNSCluster, query: Application.get_env(:fastest_music_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: FastestMusicApi.PubSub},

      # L1 Cache — ETS tables (must start before CacheWarmer)
      FastestMusicApi.Cache.EtsCache,

      # L1 Cache warmer — loads from Postgres into ETS on boot
      FastestMusicApi.Cache.CacheWarmer,

      # Circuit breaker — tracks health of external API sources
      FastestMusicApi.Sources.CircuitBreaker,

      # Health checker — pings sources every 60s
      FastestMusicApi.Health.HealthChecker,

      # HTTP server (must be last — starts accepting requests)
      FastestMusicApiWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: FastestMusicApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    FastestMusicApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
