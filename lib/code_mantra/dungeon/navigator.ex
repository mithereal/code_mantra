defmodule CodeMantra.Dungeon.Navigator do
  @moduledoc """
  Handles entity movement and navigation across room tile grids with
  collision detection and interaction triggers.
  """
  alias CodeMantra.Dungeon.Room

  @type direction :: :up | :down | :left | :right
  @type position :: {integer(), integer()}

  @spec move(Room.t(), position(), direction()) :: {:ok, position(), atom()} | {:error, atom()}
  def move(%Room{width: w, height: h, tiles: tiles} = _room, {x, y} = _current_pos, direction) do
    {dx, dy} = delta(direction)
    target = {x + dx, y + dy}

    case Map.get(tiles, target) do
      :floor ->
        {:ok, target, :none}

      :chest ->
        {:ok, target, :chest_opened}

      :obstacle ->
        {:error, :blocked_by_obstacle}

      :wall ->
        {:error, :blocked_by_wall}

      nil ->
        {:error, :out_of_bounds}
    end
  end

  defp delta(:up), do: {0, -1}
  defp delta(:down), do: {0, 1}
  defp delta(:left), do: {-1, 0}
  defp delta(:right), do: {1, 0}
end
