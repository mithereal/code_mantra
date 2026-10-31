defmodule CodeMantra.Gamification.FamiliarCosmetics do
  @moduledoc """
  Handles AI familiar cosmetic progression, evolutionary form transformations,
  and pixel particle configurations for canvas rendering.
  """

  @evolution_tiers %{
    1 => %{form: "Fledgling Sprite", scale: 0.8, aura_particles: :subtle_glow},
    10 => %{form: "Evolved Companion", scale: 1.2, aura_particles: :rune_orbit},
    25 => %{form: "Apex Guardian", scale: 1.6, aura_particles: :elemental_storm}
  }

  @type_skins %{
    copilot: ["Default Cybernetic", "Neon Synthwave", "Overclocked Gold"],
    claude: ["Default Arcane Owl", "Void Scholar", "Starlight Celestial"],
    ollama: ["Default Local Drake", "Offline Rust-Forged", "Bare-Metal Obsidian"]
  }

  @doc "Calculates current visual properties based on level, model type, and equipped skin"
  def get_visual_manifest(level, model_type, equipped_skin) do
    evolution = resolve_evolution_tier(level)
    available_skins = Map.get(@type_skins, model_type, ["Standard Familiar"])

    skin =
      if equipped_skin in available_skins, do: equipped_skin, else: List.first(available_skins)

    %{
      form_name: evolution.form,
      scale_factor: evolution.scale,
      particle_effect: evolution.aura_particles,
      skin_name: skin,
      glitch_overlay: false
    }
  end

  @doc "Triggers a glitched particle overlay when the familiar encounters hallucinated code"
  def apply_hallucination_glitch(visual_manifest) do
    %{visual_manifest | particle_effect: :crt_scanline_corruption, glitch_overlay: true}
  end

  defp resolve_evolution_tier(level) do
    cond do
      level >= 25 -> @evolution_tiers[25]
      level >= 10 -> @evolution_tiers[10]
      true -> @evolution_tiers[1]
    end
  end
end
