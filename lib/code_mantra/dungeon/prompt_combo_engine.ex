defmodule CodeMantra.Dungeon.PromptComboEngine do
  @moduledoc """
  Translates natural language AI prompts into combat spell combos,
  granting damage multipliers and status clears during boss fights.
  """

  @type spell_result :: %{
          spell_name: String.t(),
          element: atom(),
          base_damage: integer(),
          buff_type: atom() | nil,
          multiplier: float()
        }

  @doc "Parses the AI prompt text and computes the combat combo effect"
  @spec process_prompt(String.t(), integer()) :: {:ok, spell_result()}
  def process_prompt(prompt_text, familiar_level) do
    text = String.downcase(prompt_text)

    {spell, element, base_dmg, buff} =
      cond do
        String.contains?(text, ["refactor", "clean up", "optimize"]) ->
          {"Refactoring Arcane Surge", :arcane, 150, :tech_debt_shredder}

        String.contains?(text, ["test", "exunit", "spec", "coverage"]) ->
          {"Test Suite Barrier", :holy, 80, :aegis_shield_boost}

        String.contains?(text, ["fix", "bug", "error", "debug"]) ->
          {"Bug Squashing Lightning", :electric, 120, :instant_cooldown_reset}

        String.contains?(text, ["explain", "document", "docstring"]) ->
          {"Scroll of Enlightenment", :light, 50, :flow_state_boost}

        true ->
          {"Standard Magic Missile", :neutral, 40, nil}
      end

    level_multiplier = 1.0 + familiar_level * 0.05
    final_damage = round(base_dmg * level_multiplier)

    {:ok,
     %{
       spell_name: spell,
       element: element,
       base_damage: final_damage,
       buff_type: buff,
       multiplier: level_multiplier
     }}
  end
end
