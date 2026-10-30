defmodule CodeMantra.Actors.DungeonOrchestrator do
  @moduledoc """
  Actor 5: DUNGEON ORCHESTRATOR (Monorepo Raid Engine).
  Coordinates real-time multiplayer dungeons, branch-shifting hazards,
  and shared boss aggro across team repositories.
  """
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def process_remote_push(repo_id, pusher_id, commit_payload) do
    GenServer.cast(__MODULE__, {:remote_push_detected, repo_id, pusher_id, commit_payload})
  end

  def deploy_class_shield(repo_id, defender_id, target_teammate_id, class_type) do
    GenServer.call(__MODULE__, {:class_shield, repo_id, defender_id, target_teammate_id, class_type})
  end

  @impl true
  def init(state) do
    Logger.info("[DUNGEON_ORCHESTRATOR] Monorepo Raid Coordinator initialized.")
    {:ok, state}
  end

  @impl true
  def handle_cast({:remote_push_detected, repo_id, pusher_id, commit_payload}, state) do
    unless commit_payload.build_successful do
      severity = length(commit_payload["files_changed"] || [])

      Logger.error("🚨 [GIT FRACTURE]: Corrupted push detected in #{repo_id} by #{pusher_id}! Severity: #{severity}")

      CodeMantraWeb.Endpoint.broadcast!("repo_dungeon:#{repo_id}", "git_fracture", %{
        hazard_origin: pusher_id,
        severity: severity,
        burning_rows: true,
        alert_banner: "⚠️ WARNING: A corrupted commit has fractured the current directory layer!"
      })
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:class_shield, repo_id, defender_id, target_teammate_id, class_type}, _from, state) do
    shield_type = case class_type do
      :oop -> "Encapsulation Wall"
      :functional -> "Pure Function Rollback Shield"
      :low_level -> "Register Memory Barrier"
      _ -> "Basic Code Shield"
    end

    CodeMantraWeb.Endpoint.broadcast!("repo_dungeon:#{repo_id}", "boss_aggro_shielded", %{
      defender: defender_id,
      protected_player: target_teammate_id,
      shield_type: shield_type
    })

    Logger.info("🛡️ [RAID] #{defender_id} (#{class_type}) deployed #{shield_type} for #{target_teammate_id}!")
    {:reply, {:ok, shield_type}, state}
  end
end