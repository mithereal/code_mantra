defmodule CodeMantraWeb.TelemetryChannel do
  use Phoenix.Channel

  alias CodeMantra.Dungeon.FlowState

  @doc "Ingests high-frequency IDE telemetry payloads (typing speed, active buffer, idle state)"
  def handle_in(
        "ide_telemetry",
        %{"wpm" => wpm, "file_path" => file, "idle_seconds" => idle},
        socket
      ) do
    user_id = socket.assigns.current_user_id
    realm_id = socket.assigns.realm_id

    # Update the player's active flow actor state
    {:ok, flow_state} = FlowState.update_telemetry(user_id, %{wpm: wpm, file: file, idle: idle})

    # Broadcast updated aura & multipliers to the live dungeon canvas
    broadcast!(socket, "flow_updated", %{
      user_id: user_id,
      multiplier: flow_state.multiplier,
      aura: flow_state.aura_type
    })

    {:reply, :ok, socket}
  end
end
