defmodule CodeMantra.Domain.VendorArmory do
  @moduledoc """
  Procedural weapon and equipment generator based on language paradigms.
  """

  def forge_weapon(language_id, complexity_score) do
    base_item = map_language_to_base_weapon(language_id)

    %{
      name: "#{base_item.prefix} #{base_item.type}",
      rarity: calculate_rarity(complexity_score),
      damage_multiplier: 1.0 + (complexity_score * 0.05),
      durability: 100,
      elemental_affinity: base_item.affinity
    }
  end

  defp map_language_to_base_weapon("elixir"), do: %{prefix: "Supervised", type: "Staff of Concurrency", affinity: :telemetry}
  defp map_language_to_base_weapon("rust"), do: %{prefix: "Borrow-Checked", type: "Alloy Blade", affinity: :memory_safety}
  defp map_language_to_base_weapon("typescript"), do: %{prefix: "Strict-Typed", type: "Rapier", affinity: :type_guard}
  defp map_language_to_base_weapon(_), do: %{prefix: "Generic", type: "Plaintext Shortsword", affinity: :neutral}

  defp calculate_rarity(score) when score > 20, do: :mythic
  defp calculate_rarity(score) when score > 12, do: :epic
  defp calculate_rarity(score) when score > 5, do: :rare
  defp calculate_rarity(_), do: :common
end