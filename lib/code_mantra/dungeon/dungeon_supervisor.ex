defmodule CodeMantra.Dungeon.DungeonSupervisor do
  @moduledoc """
  DynamicSupervisor managing active dungeon actors and boss encounter engines.
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

  @doc "Spawns a dynamic boss encounter engine for a realm/repo"
  def start_boss_encounter(realm_id, boss_name, initial_hp) do
    spec = {CodeMantra.Dungeon.BossEncounterEngine, {realm_id, boss_name, initial_hp}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end