defmodule CodeMantra.Dungeon.DungeonOrchestrator do
  @moduledoc """
  Manages real-time multiplayer dungeons, branch-shifting hazards,
  and shared boss aggro per repository realm using a Registry-backed GenServer model.
  """
  use GenServer, restart: :transient
  require Logger

  defstruct [:repo_id, active_shields: %{}, active_hazards: []]

  # --- Client API ---

  def start_link(repo_id) do
    GenServer.start_link(__MODULE__, repo_id, name: via_tuple(repo_id))
  end

  def via_tuple(repo_id) do
    {:via, Registry, {CodeMantra.DungeonRegistry, "dungeon:#{repo_id}"}}
  end

  @doc """
  Ensures a dungeon orchestrator process is running for the given repo, then processes a push.
  """
  def process_remote_push(repo_id, pusher_id, commit_payload) do
    ensure_started(repo_id)
    GenServer.cast(via_tuple(repo_id), {:remote_push_detected, pusher_id, commit_payload})
  end

  @doc """
  Deploys a class-specific defensive shield within the repo's active dungeon.
  """
  def deploy_class_shield(repo_id, defender_id, target_teammate_id, class_type) do
    ensure_started(repo_id)
    GenServer.call(via_tuple(repo_id), {:class_shield, defender_id, target_teammate_id, class_type})
  end

  # --- Server Callbacks ---

  @impl true
  def init(repo_id) do
    Logger.info("[DUNGEON_ORCHESTRATOR] Initialized dungeon process for repository: #{repo_id}")
    {:ok, %__MODULE__{repo_id: repo_id}}
  end

  @impl true
  def handle_cast({:remote_push_detected, pusher_id, commit_payload}, state) do
    build_successful =
      case Map.fetch(commit_payload, :build_successful) do
        {:ok, val} -> val
        :error -> Map.get(commit_payload, "build_successful", true)
      end

    unless build_successful do
      files_changed = Map.get(commit_payload, :files_changed) || Map.get(commit_payload, "files_changed", [])
      severity = length(files_changed)

      Logger.error(
        "🚨 [GIT FRACTURE]: Corrupted push detected in #{state.repo_id} by #{pusher_id}! Severity: #{severity}"
      )

      CodeMantraWeb.Endpoint.broadcast!("repo_dungeon:#{state.repo_id}", "git_fracture", %{
        hazard_origin: pusher_id,
        severity: severity,
        burning_rows: true,
        alert_banner: "⚠️ WARNING: A corrupted commit has fractured the current directory layer!"
      })
    end

    {:noreply, state}
  end

  @impl true
  def handle_call(
        {:class_shield, defender_id, target_teammate_id, class_type},
        _from,
        state
      ) do
    shield_type =
      case class_type do
        :oop -> "Encapsulation Wall"
        :functional -> "Pure Function Rollback Shield"
        :low_level -> "Register Memory Barrier"
        _ -> "Basic Code Shield"
      end

    updated_shields = Map.put(state.active_shields, defender_id, %{
      target: target_teammate_id,
      type: shield_type,
      applied_at: DateTime.utc_now()
    })

    CodeMantraWeb.Endpoint.broadcast!("repo_dungeon:#{state.repo_id}", "boss_aggro_shielded", %{
      defender: defender_id,
      protected_player: target_teammate_id,
      shield_type: shield_type
    })

    Logger.info(
      "🛡️ [RAID] #{defender_id} (#{class_type}) deployed #{shield_type} for #{target_teammate_id} in #{state.repo_id}!"
    )

    {:reply, {:ok, shield_type}, %{state | active_shields: updated_shields}}
  end

  # --- Internal Helpers ---

  defp ensure_started(repo_id) do
    case Registry.lookup(CodeMantra.DungeonRegistry, "dungeon:#{repo_id}") do
      [{pid, _}] ->
        pid

      [] ->
        case DynamicSupervisor.start_child(
               CodeMantra.BossSupervisor,
               {__MODULE__, repo_id}
             ) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
    end
  end
end