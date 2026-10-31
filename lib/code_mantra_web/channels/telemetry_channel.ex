defmodule CodeMantraWeb.TelemetryChannel do
  use Phoenix.Channel

  alias CodeMantra.Dungeon.FlowState
  alias CodeMantra.Dungeon.PlayerActor

  @impl true
  def join("telemetry:session", _payload, socket) do
    user_id = socket.assigns.user_id
    tenant_id = socket.assigns.tenant_id

    # Locate existing PlayerActor or request startup from Registry/Supervisor
    case Registry.lookup(CodeMantra.PlayerRegistry, user_id) do
      [{pid, _value}] ->
        {:ok, assign(socket, :actor_pid, pid)}

      [] ->
        {:ok, pid} = CodeMantra.Dungeon.PlayerSupervisor.start_player(user_id, tenant_id)
        {:ok, assign(socket, :actor_pid, pid)}
    end
  end

  @impl true
  def handle_in("pulse", %{"keystrokes" => count, "event_type" => type} = payload, socket) do
    pid = socket.assigns.actor_pid

    # Normalize incoming editor telemetry packet
    telemetry = %{
      keystrokes: count,
      event_type: String.to_existing_atom(type),
      editor: Map.get(payload, "editor", "neovim"),
      file_path: Map.get(payload, "file_path", ""),
      timestamp: System.system_time(:millisecond)
    }

    # Forward to PlayerActor GenServer
    PlayerActor.push_telemetry(pid, telemetry)

    {:reply, :ok, socket}
  end

  @impl true
  def handle_in("file_saved", %{"file_path" => file_path}, socket) do
    pid = socket.assigns.actor_pid

    PlayerActor.push_telemetry(pid, %{
      keystrokes: 1,
      event_type: :file_saved,
      file_path: file_path,
      timestamp: System.system_time(:millisecond)
    })

    {:reply, {:ok, %{status: :flourish_triggered}}, socket}
  end

  # Broadcast player stats back to editor status line (e.g., Neovim Lualine / VS Code status bar)
  @impl true
  def handle_info({:player_stat_update, stats}, socket) do
    push(socket, "stat_sync", stats)
    {:noreply, socket}
  end

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
