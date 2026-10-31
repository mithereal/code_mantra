defmodule CodeMantra.Dungeon.Pathfinder do
  @moduledoc """
  A* Pathfinding implementation for 16-bit Zelda-style grid navigation.
  """
  alias CodeMantra.Dungeon.Room

  @spec find_path(Room.t(), {integer(), integer()}, {integer(), integer()}) :: [
          {integer(), integer()}
        ]
  def find_path(%Room{tiles: tiles, width: w, height: h}, start, goal) do
    # Priority queue storing {f_score, g_score, current_pos, path}
    open_set = [{manhattan(start, goal), 0, start, [start]}]
    closed_set = MapSet.new()

    do_find_path(open_set, closed_set, goal, tiles, w, h)
  end

  defp do_find_path([], _closed, _goal, _tiles, _w, _h), do: []

  defp do_find_path([{_f, g, current, path} | rest], closed, goal, tiles, w, h) do
    if current == goal do
      Enum.reverse(path)
    else
      if MapSet.member?(closed, current) do
        do_find_path(rest, closed, goal, tiles, w, h)
      else
        new_closed = MapSet.put(closed, current)

        neighbors =
          get_neighbors(current, tiles, w, h)
          |> Enum.reject(fn n -> MapSet.member?(new_closed, n) end)

        new_nodes =
          Enum.map(neighbors, fn next ->
            new_g = g + 1
            new_f = new_g + manhattan(next, goal)
            {new_f, new_g, next, [next | path]}
          end)

        updated_open = merge_sorted(rest, new_nodes)
        do_find_path(updated_open, new_closed, goal, tiles, w, h)
      end
    end
  end

  defp get_neighbors({x, y}, tiles, w, h) do
    [{0, -1}, {0, 1}, {-1, 0}, {1, 0}]
    |> Enum.map(fn {dx, dy} -> {x + dx, y + dy} end)
    |> Enum.filter(fn {nx, ny} ->
      nx >= 0 and ny >= 0 and nx < w and ny < h and
        Map.get(tiles, {nx, ny}) in [:floor, :chest]
    end)
  end

  defp manhattan({x1, y1}, {x2, y2}), do: abs(x1 - x2) + abs(y1 - y2)

  defp merge_sorted(list1, list2) do
    Enum.sort_by(list1 ++ list2, fn {f, _, _, _} -> f end)
  end
end
