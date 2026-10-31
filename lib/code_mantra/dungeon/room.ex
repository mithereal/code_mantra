defmodule CodeMantra.Dungeon.Room do
  @moduledoc """
  Generates 16-bit Zelda-style dungeon rooms with walls, floor tiles, and obstacles.
  """

  @type tile_type :: :wall | :floor | :obstacle | :chest
  @type t :: %__MODULE__{
          width: non_neg_integer(),
          height: non_neg_integer(),
          depth: non_neg_integer(),
          tiles: %{{non_neg_integer(), non_neg_integer()} => tile_type()},
          monsters: list(map())
        }

  defstruct [:width, :height, :depth, :tiles, :monsters]

  @default_width 25
  @default_height 15

  def generate(depth \\ 1, width \\ @default_width, height \\ @default_height) do
    tiles =
      for x <- 0..(width - 1),
          y <- 0..(height - 1),
          into: %{} do
        cond do
          x == 0 or x == width - 1 or y == 0 or y == height - 1 ->
            {{x, y}, :wall}

          :rand.uniform() < 0.10 ->
            {{x, y}, :obstacle}

          :rand.uniform() < 0.02 ->
            {{x, y}, :chest}

          true ->
            {{x, y}, :floor}
        end
      end

    monsters = spawn_monsters(depth, width, height)

    %__MODULE__{
      width: width,
      height: height,
      depth: depth,
      tiles: tiles,
      monsters: monsters
    }
  end

  defp spawn_monsters(depth, width, height) do
    count = min(3 + depth, 10)

    1..count
    |> Enum.map(fn id ->
      %{
        id: id,
        type: if(:rand.uniform() > 0.5, do: :slime, else: :skeleton),
        x: _rx = _rand_coord(width - 2),
        y: _ry = _rand_coord(height - 2),
        hp: 50 + depth * 10
      }
    end)
  end

  defp _rand_coord(max), do: :rand.uniform(max)
end
