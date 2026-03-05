defmodule FastestMusicApi.Health.HealthChecker do
  @moduledoc """
  Periodic health checker that pings external sources every 60 seconds.

  Reports source availability + circuit breaker state for the /api/health endpoint.
  """
  use GenServer
  require Logger

  @check_interval_ms 60_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc "Get current health status."
  def status do
    GenServer.call(__MODULE__, :status)
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(_) do
    state = %{
      itunes: %{status: :unknown, last_check: nil, latency_ms: nil},
      musicbrainz: %{status: :unknown, last_check: nil, latency_ms: nil},
      postgres: %{status: :unknown, last_check: nil}
    }
    schedule_check()
    # Run initial check after a short delay to let the app boot
    Process.send_after(self(), :check, 2_000)
    {:ok, state}
  end

  @impl true
  def handle_info(:check, _state) do
    new_state = %{
      itunes: check_itunes(),
      musicbrainz: check_musicbrainz(),
      postgres: check_postgres()
    }
    schedule_check()
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    circuit_status = FastestMusicApi.Sources.CircuitBreaker.status()

    response = %{
      "status" => overall_status(state),
      "sources" => %{
        "itunes" => %{
          "status" => to_string(state.itunes.status),
          "circuit" => to_string(Map.get(circuit_status, :itunes, %{})[:state] || :unknown),
          "latency_ms" => state.itunes[:latency_ms],
          "last_check" => format_time(state.itunes.last_check)
        },
        "musicbrainz" => %{
          "status" => to_string(state.musicbrainz.status),
          "circuit" => to_string(Map.get(circuit_status, :musicbrainz, %{})[:state] || :unknown),
          "latency_ms" => state.musicbrainz[:latency_ms],
          "last_check" => format_time(state.musicbrainz.last_check)
        },
        "postgres" => %{
          "status" => to_string(state.postgres.status),
          "last_check" => format_time(state.postgres.last_check)
        }
      },
      "timestamp" => DateTime.to_iso8601(DateTime.utc_now())
    }

    {:reply, response, state}
  end

  # --- Private ---

  defp check_itunes do
    start = System.monotonic_time(:millisecond)
    result = try do
      case Req.get("https://itunes.apple.com/search?term=test&limit=1&media=music",
        receive_timeout: 5_000
      ) do
        {:ok, %{status: 200}} -> :healthy
        _ -> :degraded
      end
    rescue
      _ -> :down
    end
    elapsed = System.monotonic_time(:millisecond) - start
    %{status: result, last_check: DateTime.utc_now(), latency_ms: elapsed}
  end

  defp check_musicbrainz do
    start = System.monotonic_time(:millisecond)
    result = try do
      case Req.get("https://musicbrainz.org/ws/2/release-group?query=test&limit=1&fmt=json",
        headers: [{"user-agent", "FastestMusicApi/1.0"}],
        receive_timeout: 8_000
      ) do
        {:ok, %{status: 200}} -> :healthy
        _ -> :degraded
      end
    rescue
      _ -> :down
    end
    elapsed = System.monotonic_time(:millisecond) - start
    %{status: result, last_check: DateTime.utc_now(), latency_ms: elapsed}
  end

  defp check_postgres do
    result = try do
      Ecto.Adapters.SQL.query!(FastestMusicApi.Repo, "SELECT 1")
      :healthy
    rescue
      _ -> :down
    end
    %{status: result, last_check: DateTime.utc_now()}
  end

  defp overall_status(state) do
    statuses = [state.itunes.status, state.musicbrainz.status, state.postgres.status]
    cond do
      Enum.all?(statuses, &(&1 == :healthy)) -> "healthy"
      :postgres in Enum.filter([:itunes, :musicbrainz, :postgres], fn s -> Map.get(state, s).status == :down end) -> "unhealthy"
      Enum.any?(statuses, &(&1 == :down)) -> "degraded"
      true -> "unknown"
    end
  end

  defp schedule_check do
    Process.send_after(self(), :check, @check_interval_ms)
  end

  defp format_time(nil), do: nil
  defp format_time(dt), do: DateTime.to_iso8601(dt)
end
