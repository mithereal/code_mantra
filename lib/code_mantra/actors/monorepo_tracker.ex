defmodule CodeMantra.Actors.MonorepoTracker do
  @moduledoc """
  Actor 10: MONOREPO TRACKER.
  Monitors package dependency graphs, tracks cross-module build status,
  and coordinates real-time synchronization across monorepo services.
  """
  use GenServer
  require Logger

  @sync_interval 5_000

  # --- Client API ---
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def register_package(package_id, metadata) do
    GenServer.call(__MODULE__, {:register_package, package_id, metadata})
  end

  def update_build_status(package_id, status) do
    GenServer.cast(__MODULE__, {:update_status, package_id, status})
  end

  def get_monorepo_graph do
    GenServer.call(__MODULE__, :get_graph)
  end

  # --- Server Callbacks ---
  @impl true
  def init(_opts) do
    state = %{packages: %{}}
    Logger.info("[MONOREPO_TRACKER] Initialized and monitoring monorepo package network.")
    schedule_sync()
    {:ok, state}
  end

  @impl true
  def handle_call({:register_package, package_id, metadata}, _from, state) do
    Logger.info("📦 [MONOREPO_TRACKER] Registered package: #{package_id}")

    package_entry = Map.merge(%{status: :healthy, last_updated: System.system_time(:second)}, metadata)
    updated_packages = Map.put(state.packages, package_id, package_entry)

    {:reply, {:ok, package_id}, %{state | packages: updated_packages}}
  end

  @impl true
  def handle_call(:get_graph, _from, state) do
    {:reply, state.packages, state}
  end

  @impl true
  def handle_cast({:update_status, package_id, status}, state) do
    case Map.get(state.packages, package_id) do
      nil ->
        Logger.warning("[MONOREPO_TRACKER] Attempted to update unknown package: #{package_id}")
        {:noreply, state}

      package ->
        updated_package = %{package | status: status, last_updated: System.system_time(:second)}
        updated_packages = Map.put(state.packages, package_id, updated_package)

        Logger.info("🔄 [MONOREPO_TRACKER] Package #{package_id} status updated to: #{status}")

        CodeMantraWeb.Endpoint.broadcast!("monorepo:network", "package_status_changed", %{
          package_id: package_id,
          status: status
        })

        {:noreply, %{state | packages: updated_packages}}
    end
  end

  @impl true
  def handle_info(:sync_tick, state) do
    # Periodic background verification of monorepo package tree health
    schedule_sync()
    {:noreply, state}
  end

  # --- Internal Helpers ---
  defp schedule_sync do
    Process.send_after(self(), :sync_tick, @sync_interval)
  end
end