defmodule CodeMantra.Dungeon.MonsterGenerator do
  @moduledoc """
  Procedurally generates unique monster types based on code smells,
  syntax errors, and repository depth.
  """

  @prefixes [
    "NullPointer",
    "Async",
    "RaceCondition",
    "MemoryLeaking",
    "Cyclomatic",
    "Deprecated",
    "Uncaught",
    "Legacy"
  ]
  @suffixes ["Goblin", "Wraith", "Viper", "Golem", "Behemoth", "Daemon", "Spectre", "Zombie"]

  @spec generate(non_neg_integer()) :: map()
  def generate(realm_depth) do
    name = "#{Enum.random(@prefixes)} #{Enum.random(@suffixes)}"
    base_hp = 30 + realm_depth * 15

    %{
      name: name,
      type: infer_monster_class(name),
      hp: base_hp,
      max_hp: base_hp,
      attack_power: 5 + round(realm_depth * 1.2),
      speed: :rand.uniform(3) + 1,
      loot_multiplier: 1.0 + realm_depth * 0.1
    }
  end

  defp infer_monster_class(name) do
    cond do
      String.contains?(name, ["NullPointer", "RaceCondition"]) -> :aggressive_chaser
      String.contains?(name, ["MemoryLeaking", "Deprecated"]) -> :shielded_tank
      true -> :wandering_mob
    end
  end
end
