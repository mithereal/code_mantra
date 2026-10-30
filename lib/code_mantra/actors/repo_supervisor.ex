defmodule CodeMantra.Actors.RepoSupervisor do
  @moduledoc """
  Dynamically spawns and references repository dungeon GenServers
  hashed across cluster nodes using partitioned Registry.
  """

  def via_tuple(repo_id) do
    {:via, Registry, {CodeMantra.RepoRegistry, repo_id}}
  end

  def start_child(repo_id) do
    spec = {CodeMantra.Actors.DungeonOrchestrator, repo_id}
    DynamicSupervisor.start_child(CodeMantra.DungeonDynamicSupervisor, spec)
  end
end