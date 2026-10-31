defmodule CodeMantra.Application do
  @moduledoc """
  Master Application Supervision Tree for Code::Mantra.
  Boots the Cloud Core Infrastructure, Phoenix PubSub/Channels,
  and dynamic dungeon/realm supervision workers in correct sequence.
  """
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # 1. Database & Persistence
      CodeMantra.Repo,

      # 2. PubSub Grid & Endpoint Infrastructure
      {Phoenix.PubSub, name: CodeMantra.PubSub},
      CodeMantraWeb.Endpoint,

      # 3. Dynamic Process Registries
      {Registry, keys: :unique, name: CodeMantra.DungeonRegistry},
      {Registry, keys: :unique, name: CodeMantra.RepoRegistry, partitions: System.schedulers_online()},

      # 4. Dynamic Supervisors for Ephemeral Realm / Boss / Dungeon Processes
      {DynamicSupervisor, name: CodeMantra.BossSupervisor, strategy: :one_for_one}

      # Note: Ephemeral actors like DungeonOrchestrator and BossEncounterEngine
      # are spawned dynamically on-demand via CodeMantra.BossSupervisor using
      # the Registry pattern rather than running as static global singletons.
    ]

    opts = [strategy: :one_for_one, name: CodeMantra.Supervisor]

    Logger.info("🛡️ [CODE::MANTRA] Cloud Core Infrastructure Initialized. All Supervisors Operational.")
    Supervisor.start_link(children, opts)
  end
end