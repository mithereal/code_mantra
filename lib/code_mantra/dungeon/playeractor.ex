defmodule CodeMantra.Dungeon.PlayerActor do
  use GenServer, restart: :temporary

  # Client API to receive telemetry from the IDE extension
  def push_telemetry(pid, %{keystrokes: count, event_type: type} = telemetry) do
    GenServer.cast(pid, {:ide_telemetry, count, type, telemetry})
  end

  # GenServer Callbacks
  @impl true
  def handle_cast({:ide_telemetry, keystrokes, :active_typing, data}, state) do
    # Advance avatar position along the World Tree path
    new_position = state.position_x + keystrokes * state.flow_multiplier

    # Roll for a micro-mob encounter along the path
    {state, combat_event} = maybe_spawn_and_slash_mob(state, new_position)

    # Broadcast movement & combat update to the LiveView spectator canvas
    broadcast_canvas_update(state, combat_event)

    {:noreply, state}
  end

  def handle_cast({:ide_telemetry, _count, :file_saved, _data}, state) do
    # Saving a file triggers a powerful sword flourish, clearing nearby mobs
    broadcast_canvas_update(state, %{action: :sword_flourish, target: :syntax_gremlin_cleared})
    {:noreply, %{state | combo_streak: state.combo_streak + 1}}
  end

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

  defp maybe_spawn_and_slash_mob(state, new_pos) do
    if rem(round(new_pos), 50) == 0 do
      mob = Enum.random([:syntax_gremlin, :null_pointer_bat, :whitespace_imp])
      # EXP accumulates live here in memory:
      {%{state | position_x: new_pos, xp: state.xp + 10}, %{action: :slash, mob: mob, reward: 10}}
    else
      {%{state | position_x: new_pos}, nil}
    end
  end
end
