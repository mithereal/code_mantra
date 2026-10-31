defmodule CodeMantra.Dungeon.PlayerActor do
  @moduledoc """
  Manages an active player avatar's position, experience, and combat state
  driven by live IDE telemetry.
  """
  use GenServer, restart: :temporary
  require Logger

  defstruct [
    :user_id,
    :tenant_id,
    position_x: 0.0,
    flow_multiplier: 1.0,
    xp: 0,
    combo_streak: 0
  ]

  def start_link({user_id, tenant_id}) do
    GenServer.start_link(__MODULE__, {user_id, tenant_id}, name: via_tuple(user_id))
  end

  def via_tuple(user_id) do
    {:via, Registry, {CodeMantra.RealmRegistry, "player:#{user_id}"}}
  end

  # Client API to receive telemetry from the IDE extension
  def push_telemetry(user_id, %{keystrokes: _count, event_type: _type} = telemetry) do
    ensure_started(user_id, "default-tenant")
    GenServer.cast(via_tuple(user_id), {:ide_telemetry, telemetry})
  end

  # --- GenServer Callbacks ---

  @impl true
  def init({user_id, tenant_id}) do
    state = %__MODULE__{
      user_id: user_id,
      tenant_id: tenant_id
    }
    {:ok, state}
  end

  @impl true
  def handle_cast({:ide_telemetry, %{keystrokes: count, event_type: :active_typing}}, state) do
    # Advance avatar position along the World Tree path
    new_position = state.position_x + count * state.flow_multiplier

    # Roll for a micro-mob encounter along the path
    {updated_state, combat_event} = maybe_spawn_and_slash_mob(state, new_position)

    # Broadcast movement & combat update to the LiveView spectator canvas
    broadcast_canvas_update(updated_state, combat_event)

    {:noreply, updated_state}
  end

  @impl true
  def handle_cast({:ide_telemetry, %{event_type: :file_saved}}, state) do
    # Saving a file triggers a powerful sword flourish, clearing nearby mobs
    broadcast_canvas_update(state, %{action: :sword_flourish, target: :syntax_gremlin_cleared})
    {:noreply, %{state | combo_streak: state.combo_streak + 1}}
  end

  @impl true
  def handle_cast({:ide_telemetry, _other}, state) do
    {:noreply, state}
  end

  # --- Helpers ---

  defp maybe_spawn_and_slash_mob(state, new_pos) do
    if rem(round(new_pos), 50) == 0 do
      mob = Enum.random([:syntax_gremlin, :null_pointer_bat, :whitespace_imp])
      {%{state | position_x: new_pos, xp: state.xp + 10}, %{action: :slash, mob: mob, reward: 10}}
    else
      {%{state | position_x: new_pos}, nil}
    end
  end

  defp broadcast_canvas_update(state, combat_event) do
    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "canvas:#{state.tenant_id}",
      {:avatar_moved, %{user: state.user_id, x: state.position_x, event: combat_event}}
    )
  end

  defp ensure_started(user_id, tenant_id) do
    case Registry.lookup(CodeMantra.RealmRegistry, "player:#{user_id}") do
      [{pid, _}] ->
        pid

      [] ->
        case DynamicSupervisor.start_child(
               CodeMantra.BossSupervisor,
               {__MODULE__, {user_id, tenant_id}}
             ) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
    end
  end
end