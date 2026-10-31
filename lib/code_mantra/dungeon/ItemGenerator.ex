defmodule CodeMantra.Dungeon.ItemGenerator do
  @moduledoc """
  Procedurally generates weapons, armor, and consumable items based on
  repository language ecosystem, test coverage, and realm depth.
  """

  @prefixes [
    "Asynchronous",
    "Strongly-Typed",
    "Optimized",
    "Refactored",
    "Immutable",
    "Zero-Allocation"
  ]
  @weapon_types ["Broadsword", "Staff", "Dagger", "Compiler Hammer", "Query Wand"]
  @armor_types ["Test Suite Aegis", "Type-Safe Cuirass", "Pipeline Robes", "Linter Helm"]

  @spec generate_item(non_neg_integer(), atom(), float()) :: map()
  def generate_item(realm_depth, item_class, test_coverage_pct) do
    case item_class do
      :weapon ->
        name = "#{Enum.random(@prefixes)} #{Enum.random(@weapon_types)}"
        base_dmg = 10 + round(realm_depth * 2.5)

        %{
          name: name,
          class: :weapon,
          rarity: calculate_rarity(realm_depth),
          attack_power: base_dmg,
          perk: :critical_strike_boost,
          power_multiplier: 1.0 + realm_depth * 0.05
        }

      :armor ->
        name = "#{Enum.random(@prefixes)} #{Enum.random(@armor_types)}"
        # Armor scaling is directly tied to test coverage health!
        base_defense = 5 + round(realm_depth * 1.8)
        # Scaled by test suite
        coverage_multiplier = 0.5 + test_coverage_pct * 0.01

        %{
          name: name,
          class: :armor,
          rarity: calculate_rarity(realm_depth),
          defense_power: round(base_defense * coverage_multiplier),
          perk: :ci_cd_damage_reduction
        }
    end
  end

  defp calculate_rarity(depth) do
    cond do
      depth > 50 -> :legendary
      depth > 25 -> :epic
      depth > 10 -> :rare
      true -> :common
    end
  end
end
