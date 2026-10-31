defmodule CodeMantra.Actors.ClientSocket do
  @moduledoc """
  Actor 1: CLIENT_SOCKET GATEWAY.
  Monitors active WebSocket channels from IDE clients (VS Code/Neovim)
  and dispatches high-frequency telemetry batches.
  """
  use GenServer
  require Logger

  # --- Client API ---
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{sockets: %{}}, name: __MODULE__)
  end

  def register_client(socket_pid, user_id, editor_type) do
    GenServer.call(__MODULE__, {:register, socket_pid, user_id, editor_type})
  end

  def dispatch_batch(user_id, batch_payload) do
    GenServer.cast(__MODULE__, {:dispatch, user_id, batch_payload})
  end

  # --- Server Callbacks ---
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:register, pid, user_id, editor_type}, _from, state) do
    Process.monitor(pid)
    updated_sockets = Map.put(state.sockets, pid, %{user_id: user_id, editor: editor_type})
    Logger.info("[CLIENT_SOCKET] IDE Connected: User #{user_id} via #{editor_type}")

    {:reply, :ok, %{state | sockets: updated_sockets}}
  end

  @impl true
  def handle_cast({:dispatch, user_id, batch}, state) do
    CodeMantra.Actors.EvaluationDaemon.evaluate_ast(user_id, batch)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {client_info, updated_sockets} = Map.pop(state.sockets, pid)

    if client_info do
      Logger.info("[CLIENT_SOCKET] IDE Disconnected: User #{client_info.user_id}")
    end

    {:noreply, %{state | sockets: updated_sockets}}
  end
end
