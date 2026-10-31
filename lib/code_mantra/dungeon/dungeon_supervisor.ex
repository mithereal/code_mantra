defmodule CodeMantra.Dungeon.DungeonSupervisor do
  @moduledoc """
  DynamicSupervisor managing active BranchDungeonActors and BossEncounterEngines.
  Automatically restarts crashed actors and rehydrates dungeon states.
  """
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc "Spawns or recovers a branch dungeon actor"
  def start_dungeon(realm_id, branch_name) do
    spec = {CodeMantra.Dungeon.BranchDungeonActor, {realm_id, branch_name}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
