defmodule CodeMantra.Dungeon.EditorBuffs do
  @moduledoc """
  Calculates combat buffs, attack speeds, and special passive traits
  based on the developer's connected code editor.
  """

  @spec apply_editor_buffs(atom(), map()) :: map()
  def apply_editor_buffs(editor_type, base_stats) do
    case editor_type do
      :neovim ->
        %{
          base_stats
        | attack_speed_multiplier: base_stats.attack_speed_multiplier * 1.25,
          perk: :vim_motion_combo
        }

      :vscode ->
        %{
          base_stats
        | debuff_resistance: base_stats.debuff_resistance + 0.15,
          perk: :modular_extension_slots
        }

      :jetbrains ->
        %{
          base_stats
        | shield_capacity: base_stats.shield_capacity * 1.40,
          perk: :enterprise_refactor_shockwave
        }

      :emacs ->
        %{base_stats | macro_flexibility: :infinite, perk: :lisp_macro_metamorphosis}

      _ ->
        %{base_stats | perk: :standard_baseline}
    end
  end
end