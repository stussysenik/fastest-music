defmodule FastestMusicApi.Sources.CircuitBreaker do
  @moduledoc """
  Circuit breaker pattern for external API sources.

  ## How circuit breakers work (educational)

  External APIs can fail or slow down. Without protection, our server would pile up
  requests waiting for a dead API, eventually crashing itself.

  The circuit breaker has three states:
  - :closed (healthy) — requests flow through normally
  - :open (tripped) — after N consecutive failures, we stop sending requests entirely
  - :half_open — after a cooldown period, we let ONE request through to test recovery

  This prevents cascade failures and lets the system self-heal when APIs recover.

  State transitions:
    :closed --[5 failures]--> :open --[30s cooldown]--> :half_open --[success]--> :closed
                                                                    --[failure]--> :open
  """
  use GenServer

  @failure_threshold 5
  @cooldown_ms 30_000

  defstruct [:state, :failure_count, :last_failure_at]

  # --- Public API ---

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc "Check if requests to `source` are allowed."
  def allow?(source) do
    GenServer.call(__MODULE__, {:allow?, source})
  end

  @doc "Record a successful request to `source`."
  def record_success(source) do
    GenServer.cast(__MODULE__, {:success, source})
  end

  @doc "Record a failed request to `source`."
  def record_failure(source) do
    GenServer.cast(__MODULE__, {:failure, source})
  end

  @doc "Get the current state of all circuit breakers (for health checks)."
  def status do
    GenServer.call(__MODULE__, :status)
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(_) do
    state = %{
      itunes: %__MODULE__{state: :closed, failure_count: 0, last_failure_at: nil},
      musicbrainz: %__MODULE__{state: :closed, failure_count: 0, last_failure_at: nil}
    }
    {:ok, state}
  end

  @impl true
  def handle_call({:allow?, source}, _from, state) do
    breaker = Map.get(state, source, default_breaker())

    result = case breaker.state do
      :closed -> true
      :open -> maybe_half_open?(breaker)
      :half_open -> true
    end

    # Transition to :half_open if cooldown has passed
    new_state = if breaker.state == :open and result do
      put_in(state, [source], %{breaker | state: :half_open})
    else
      state
    end

    {:reply, result, new_state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    status = Enum.map(state, fn {source, breaker} ->
      {source, %{state: breaker.state, failure_count: breaker.failure_count}}
    end)
    |> Enum.into(%{})

    {:reply, status, state}
  end

  @impl true
  def handle_cast({:success, source}, state) do
    new_state = put_in(state, [source], %__MODULE__{
      state: :closed,
      failure_count: 0,
      last_failure_at: nil
    })
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:failure, source}, state) do
    breaker = Map.get(state, source, default_breaker())

    new_count = breaker.failure_count + 1
    new_breaker_state = if new_count >= @failure_threshold, do: :open, else: breaker.state

    new_state = put_in(state, [source], %__MODULE__{
      state: new_breaker_state,
      failure_count: new_count,
      last_failure_at: System.monotonic_time(:millisecond)
    })

    {:noreply, new_state}
  end

  # --- Private ---

  defp maybe_half_open?(%{last_failure_at: nil}), do: true
  defp maybe_half_open?(%{last_failure_at: last_failure_at}) do
    System.monotonic_time(:millisecond) - last_failure_at > @cooldown_ms
  end

  defp default_breaker do
    %__MODULE__{state: :closed, failure_count: 0, last_failure_at: nil}
  end
end
