defmodule CodeMantra.Dungeon.BranchDungeonActor do
  @moduledoc """
  Manages a specific Git Branch Dungeon within a Realm.
  Maps GitHub Issues to dungeon encounter chambers and tracks PR progression.
  """
  use GenServer
  alias CodeMantra.Dungeon.{Room, Pathfinder}

  defstruct [
    :realm_id,
    :branch_name,
    :world_tree_level,
    :active_issues,
    :dungeon_rooms,
    :player_positions
  ]

  # --- Client API ---

  def start_link({realm_id, branch_name}) do
    GenServer.start_link(
      __MODULE__,
      {realm_id, branch_name},
      name: via_tuple(realm_id, branch_name)
    )
  end

  def via_tuple(realm_id, branch_name) do
    {:via, Registry, {CodeMantra.DungeonRegistry, "#{realm_id}:#{branch_name}"}}
  end

  @doc "Syncs GitHub issues into dungeon rooms"
  def sync_issues(realm_id, branch_name, issues) do
    GenServer.call(via_tuple(realm_id, branch_name), {:sync_issues, issues})
  end

  @doc "Triggers room clearance when an issue is closed"
  def close_issue_node(realm_id, branch_name, issue_id) do
    GenServer.call(via_tuple(realm_id, branch_name), {:close_issue_node, issue_id})
  end

  # --- Server Callbacks ---

  @impl true
  def init({realm_id, branch_name}) do
    state = %__MODULE__{
      realm_id: realm_id,
      branch_name: branch_name,
      world_tree_level: calculate_tree_height(branch_name),
      active_issues: %{},
      dungeon_rooms: %{},
      player_positions: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:sync_issues, issues}, _from, state) do
    # Map each issue to a procedurally generated dungeon chamber
    new_rooms =
      Enum.reduce(issues, state.dungeon_rooms, fn issue, acc ->
        room = Room.generate(state.world_tree_level)

        # Decorate room with issue metadata (Boss = Issue Title)
        room_data = %{
          room: room,
          issue_id: issue.id,
          title: issue.title,
          cleared: false,
          boss_hp: issue.comments_count * 50 + 100
        }

        Map.put(acc, issue.id, room_data)
      end)

    updated_state = %{state | dungeon_rooms: new_rooms}
    broadcast_tree_update(updated_state)

    {:reply, {:ok, map_size(new_rooms)}, updated_state}
  end

  @impl true
  def handle_call({:close_issue_node, issue_id}, _from, state) do
    case Map.get(state.dungeon_rooms, issue_id) do
      nil ->
        {:reply, {:error, :issue_not_found}, state}

      room_node ->
        # Mark issue chamber as cleared and trigger loot drop
        cleared_node = %{room_node | cleared: true, boss_hp: 0}
        updated_rooms = Map.put(state.dungeon_rooms, issue_id, cleared_node)

        updated_state = %{state | dungeon_rooms: updated_rooms}

        Phoenix.PubSub.broadcast(
          CodeMantra.PubSub,
          "realm:#{state.realm_id}",
          {:issue_chamber_cleared, %{branch: state.branch_name, issue_id: issue_id}}
        )

        {:reply, {:ok, :chamber_cleared}, updated_state}
    end
  end

  defp calculate_tree_height(branch_name) do
    case branch_name do
      # High Canopy
      "main" -> 100
      "master" -> 100
      # Middle Trunk
      "staging" -> 50
      # Root / Outer Branches
      _ -> 10
    end
  end

  defp broadcast_tree_update(state) do
    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "world_tree:#{state.realm_id}",
      {:branch_dungeon_updated, state}
    )
  end
end
