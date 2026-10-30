defmodule CodeMantra.Application do
  @moduledoc """
  Master Application Supervision Tree for Code::Mantra.
  Boots the Cloud Core Infrastructure, Phoenix PubSub/Channels,
  and isolated Actor processes in exact sequence.
  """
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # 1. Database & Telemetry Repositories
      CodeMantra.Repo,

      # 2. Phoenix PubSub Grid & Endpoint Infrastructure
      {Phoenix.PubSub, name: CodeMantra.PubSub},
      CodeMantraWeb.Endpoint,

      # 3. Core Engine Actor Processes
      CodeMantra.Actors.ClientSocket,       # Actor 1: IDE WebSocket Gateway
      CodeMantra.Actors.EvaluationDaemon,   # Actor 2: Polyglot Evaluation & Procedural Synthesis
      CodeMantra.Actors.ProgressionBalancer,# Actor 3: Shannon Entropy & XP/Gold Balancer
      CodeMantra.Actors.PersistenceDaemon,  # Actor 4: PostgreSQL Checkpoints & Runic Archive
      CodeMantra.Actors.DungeonOrchestrator,# Actor 5: Monorepo Raid Coordinator
      CodeMantra.Actors.MonolithDrop,       # Actor 6: World Boss Event Daemon
      CodeMantra.Actors.StreamAnimator,     # Stream Frame Animator
      CodeMantra.Actors.MonorepoTracker,    # Corporate Git Fracture Monitor
      CodeMantra.Actors.BossEncounterEngine,# Turn-Based Combat State Engine
      CodeMantra.Actors.CombatOrchestrator,  # Merge Conflict Encounter Handler
      {Registry, keys: :unique, name: CodeMantra.RepoRegistry, partitions: System.schedulers_online()},
      {Phoenix.PubSub, name: CodeMantra.PubSub, adapter: Phoenix.PubSub.PG2}
    ]

    opts = [strategy: :one_for_one, name: CodeMantra.Supervisor]

    Logger.info("🛡️ [CODE::MANTRA] Cloud Core Infrastructure Initialized. All Actors Operational.")
    Supervisor.start_link(children, opts)
  end
end