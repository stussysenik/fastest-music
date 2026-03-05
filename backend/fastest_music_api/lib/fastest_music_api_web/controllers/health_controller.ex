defmodule FastestMusicApiWeb.HealthController do
  @moduledoc """
  Health check endpoint.

  GET /api/health

  Returns the status of all external dependencies (iTunes, MusicBrainz, Postgres)
  plus circuit breaker states. Useful for monitoring and debugging.
  """
  use FastestMusicApiWeb, :controller

  alias FastestMusicApi.Health.HealthChecker

  def index(conn, _params) do
    status = HealthChecker.status()
    http_status = if status["status"] == "healthy", do: 200, else: 503

    conn
    |> put_status(http_status)
    |> json(status)
  end
end
