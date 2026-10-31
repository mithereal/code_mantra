defmodule CodeMantra.Dungeon.DungeonActor do
  @moduledoc """
  GenServer actor managing live room state, enemy pathfinding AI,
  and real-time PubSub broadcasts for a specific realm dungeon.
  Uses Registry-backed isolation.
  """
  use GenServer, restart: :transient
  require Logger
  alias CodeMantra.Dungeon.{Room, Pathfinder}

  # 4 updates per second for smooth monster AI
  @tick_interval 250

  defstruct [:realm_id, :room, :players, :monsters, :timer]

  # --- Client API ---

  def start_link(realm_id) do
    GenServer.start_link(__MODULE__, realm_id, name: via_tuple(realm_id))
  end

  def via_tuple(realm_id) do
    {:via, Registry, {CodeMantra.DungeonRegistry, "dungeon_room:#{realm_id}"}}
  end

  @doc "Ensures the dungeon room actor is active, then fetches state."
  def get_state(realm_id) do
    ensure_started(realm_id)
    GenServer.call(via_tuple(realm_id), :get_state)
  end

  @doc "Moves a player within the dungeon grid."
  def move_player(realm_id, user_id, direction) do
    ensure_started(realm_id)
    GenServer.call(via_tuple(realm_id), {:move_player, user_id, direction})
  end

  # --- Server Callbacks ---

  @impl true
  def init(realm_id) do
    room = Room.generate(1)
    timer = :timer.send_interval(@tick_interval, :tick)

    state = %__MODULE__{
      realm_id: realm_id,
      room: room,
      players: %{},
      monsters: room.monsters,
      timer: timer
    }

    Logger.info("🗺️ [DUNGEON_ACTOR] Initialized live dungeon room for realm: #{realm_id}")
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(
        {:move_player, user_id, direction},
        _from,
        %{room: room, players: players} = state
      ) do
    current_pos = Map.get(players, user_id, {1, 1})
    {dx, dy} = delta(direction)

    target = {
      elem(current_pos, 0) + dx,
      elem(current_pos, 1) + dy
    }

    case Map.get(room.tiles, target) do
      tile when tile in [:floor, :chest] ->
        updated_players = Map.put(players, user_id, target)
        new_state = %{state | players: updated_players}

        broadcast_state(new_state)
        {:reply, {:ok, target}, new_state}

      _ ->
        {:reply, {:error, :blocked}, state}
    end
  end

  @impl true
  def handle_info(:tick, %{room: room, monsters: monsters, players: players} = state) do
    updated_monsters =
      if map_size(players) > 0 do
        target_pos = players |> Map.values() |> hd()

        Enum.map(monsters, fn monster ->
          current_pos = {monster.x, monster.y}
          path = Pathfinder.find_path(room, current_pos, target_pos)

          case path do
            [_, next | _] -> %{monster | x: elem(next, 0), y: elem(next, 1)}
            _ -> monster
          end
        end)
      else
        monsters
      end

    new_state = %{state | monsters: updated_monsters}
    broadcast_state(new_state)

    {:noreply, new_state}
  end

  # --- Internal Helpers ---

  defp delta(:up), do: {0, -1}
  defp delta(:down), do: {0, 1}
  defp delta(:left), do: {-1, 0}
  defp delta(:right), do: {1, 0}

  defp broadcast_state(state) do
    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "room:#{state.realm_id}",
      {:room_state_updated, state}
    )
  end

  defp ensure_started(realm_id) do
    case Registry.lookup(CodeMantra.DungeonRegistry, "dungeon_room:#{realm_id}") do
      [{pid, _}] ->
        pid

      [] ->
        case DynamicSupervisor.start_child(
               CodeMantra.BossSupervisor,
               {__MODULE__, realm_id}
             ) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
    end
  end
end