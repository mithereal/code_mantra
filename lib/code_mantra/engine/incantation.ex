defmodule CodeMantra.Engine.MantraParser.Incantation do
  @moduledoc """
  Parses developer source files for tactical `@mantra` ritual blocks
  and translates them into active RPG buffs or code purification spells.
  """

  @supported_mantras %{
    "purify_debt" => %{effect: :reduce_legacy_ratio, value: 0.1, cost: 50},
    "chronomancer_shield" => %{effect: :pure_function_rollback, duration_min: 15, cost: 100},
    "strict_type_strike" => %{effect: :critical_multiplier_buff, multiplier: 2.0, cost: 75}
  }

  def scan_and_cast(content, user_id) do
    # Scan for mantra annotations like: # @mantra: purify_debt
    regex = ~r/\/\/\s*@mantra:\s*([a-zA-Z_]+)|#\s*@mantra:\s*([a-zA-Z_]+)/
    matches = Regex.scan(regex, content)

    Enum.reduce(matches, [], fn match, acc ->
      mantra_key = List.last(match)

      case Map.get(@supported_mantras, mantra_key) do
        nil ->
          acc

        spell ->
          execute_spell(user_id, mantra_key, spell)
          [spell | acc]
      end
    end)
  end

  defp execute_spell(user_id, mantra_key, spell) do
    require Logger

    Logger.info(
      "🔮 [MANTRA ENGINE] User #{user_id} chanted mantra '@mantra:#{mantra_key}'! Casting #{spell.effect}..."
    )

    # Broadcast spell visual effect via Phoenix PubSub
    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "world_crawl_feed",
      {:mantra_cast, %{user_id: user_id, mantra: mantra_key, effect: spell.effect}}
    )
  end
end
