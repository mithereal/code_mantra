defmodule CodeMantra.Domain.VendorArmory do
  @moduledoc """
  Procedural weapon and equipment generator based on programming language paradigms
  and cyclomatic complexity scores. Returns attribute maps suitable for forging `ArmoryItem` resources.
  """

  @doc """
  Forges procedural armory item attributes given a target programming language and complexity metric.
  """
  @spec forge_weapon(String.t(), number(), String.t() | nil) :: map()
  def forge_weapon(language_id, complexity_score, player_id \\ nil) do
    base_item = map_language_to_base_weapon(String.downcase(language_id || ""))
    rarity = calculate_rarity(complexity_score)
    damage_mult = Float.round(1.0 + complexity_score * 0.05, 2)

    %{
      name: "#{base_item.prefix} #{base_item.type}",
      rarity: rarity,
      damage_multiplier: damage_mult,
      durability: 100,
      affinity: base_item.affinity,
      player_id: player_id
    }
  end

  defp map_language_to_base_weapon("elixir"),
       do: %{prefix: "Supervised", type: "Staff of Concurrency", affinity: :concurrency}

  defp map_language_to_base_weapon("rust"),
       do: %{prefix: "Borrow-Checked", type: "Alloy Blade", affinity: :low_level}

  defp map_language_to_base_weapon("typescript"),
       do: %{prefix: "Strict-Typed", type: "Rapier", affinity: :architectural}

  defp map_language_to_base_weapon("haskell"),
       do: %{prefix: "Purely Functional", type: "Monadic Wand", affinity: :functional}

  defp map_language_to_base_weapon(_),
       do: %{prefix: "Generic", type: "Plaintext Shortsword", affinity: :telemetry}

  defp calculate_rarity(score) when score > 20, do: :mythic
  defp calculate_rarity(score) when score > 12, do: :epic
  defp calculate_rarity(score) when score > 5, do: :rare
  defp calculate_rarity(_), do: :common
end