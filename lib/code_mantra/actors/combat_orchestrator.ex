defmodule CodeMantra.Actors.CombatOrchestrator do
  @moduledoc """
  Actor 8: COMBAT ORCHESTRATOR.
  Manages real-time tactical combat sessions, turn queues, spell execution,
  and status effect ticks across connected IDE clients.
  """
  use GenServer
  require Logger

  @tick_interval 1_000

  # --- Client API ---
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init_combat(session_id, participants) do
    GenServer.call(__MODULE__, {:init_combat, session_id, participants})
  end

  def submit_action(session_id, actor_id, action_payload) do
    GenServer.cast(__MODULE__, {:submit_action, session_id, actor_id, action_payload})
  end

  def get_session_state(session_id) do
    GenServer.call(__MODULE__, {:get_state, session_id})
  end

  # --- Server Callbacks ---
  @impl true
  def init(_opts) do
    state = %{sessions: %{}}
    Logger.info("[COMBAT_ORCHESTRATOR] Initialized and ready for tactical code combat.")
    schedule_tick()
    {:ok, state}
  end

  @impl true
  def handle_call({:init_combat, session_id, participants}, _from, state) do
    Logger.info("⚔️ [COMBAT_ORCHESTRATOR] Initializing combat session #{session_id} with #{length(participants)} participants.")

    session_data = %{
      session_id: session_id,
      participants: Map.new(participants, fn p -> {p.id, Map.merge(%{hp: 100, max_hp: 100, status: :active, effects: []}, p)} end),
      turn_queue: Enum.map(participants, & &1.id),
      current_turn: List.first(participants)[:id],
      status: :active
    }

    updated_sessions = Map.put(state.sessions, session_id, session_data)
    broadcast_combat_state(session_data)

    {:reply, {:ok, session_id}, %{state | sessions: updated_sessions}}
  end

  @impl true
  def handle_call({:get_state, session_id}, _from, state) do
    session = Map.get(state.sessions, session_id)
    {:reply, session, state}
  end

  @impl true
  def handle_cast({:submit_action, session_id, actor_id, action_payload}, state) do
    case Map.get(state.sessions, session_id) do
      %{status: :active, current_turn: ^actor_id} = session ->
        action_type = Map.get(action_payload, :type) || Map.get(action_payload, "type", :strike)
        power = Map.get(action_payload, :power) || Map.get(action_payload, "power", 15)

        Logger.info("⚡ [COMBAT_ORCHESTRATOR] Actor #{actor_id} executed #{action_type} with power #{power} in session #{session_id}")

        # Rotate turn queue
        updated_queue = List.delete(session.turn_queue, actor_id) ++ [actor_id]
        next_turn = List.first(updated_queue)

        updated_session = %{session | turn_queue: updated_queue, current_turn: next_turn}
        broadcast_combat_state(updated_session)

        {:noreply, %{state | sessions: Map.put(state.sessions, session_id, updated_session)}}

      _ ->
        Logger.warning("[COMBAT_ORCHESTRATOR] Rejected action from #{actor_id}: not their turn or inactive session.")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:tick, state) do
    # Periodic tick to process status effects or turn timeouts across active sessions
    schedule_tick()
    {:noreply, state}
  end

  # --- Internal Helpers ---
  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval)
  end

  defp broadcast_combat_state(session) do
    CodeMantraWeb.Endpoint.broadcast!("combat:#{session.session_id}", "combat_state_update", %{
      current_turn: session.current_turn,
      participants: session.participants,
      status: session.status
    })
  end
end