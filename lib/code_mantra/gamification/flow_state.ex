defmodule CodeMantra.Gamification.FlowState do
  @moduledoc """
  Tracks IDE telemetry duration and calculates escalating Flow State
  auras and multipliers.
  """

  @spec evaluate_telemetry(String.t(), map()) :: {:active | :fragmented | :normal, map()}
  def evaluate_telemetry(_user_id, telemetry) do
    %{
      uninterrupted_time_ms: time_ms,
      wpm: wpm,
      file_switches_count: file_switches,
      idle_time_ms: idle_ms
    } = telemetry

    cond do
      file_switches > 4 and time_ms < 600_000 ->
        {:fragmented, %{status: :context_switch_penalty, damage_multiplier: 0.8}}

      # 60+ minutes
      time_ms >= 3_600_000 ->
        {:active, build_flow_tier(:yggdrasil_ascendant, 4.0, wpm, 3.5)}

      # 40+ minutes
      time_ms >= 2_400_000 ->
        {:active, build_flow_tier(:void_prism, 3.0, wpm, 3.0)}

      # 20+ minutes
      time_ms >= 1_200_000 ->
        {:active, build_flow_tier(:golden_radiance, 2.5, wpm, 2.5)}

      # 10+ minutes
      time_ms >= 600_000 ->
        {:active, build_flow_tier(:cyan_flame, 2.0, wpm, 2.0)}

      true ->
        {:normal, %{status: :standard, damage_multiplier: 1.0, loot_multiplier: 1.0, aura: :none}}
    end
  end

  defp build_flow_tier(aura_name, base_dmg_mult, wpm, loot_mult) do
    %{
      status: :hyper_focus,
      aura: aura_name,
      damage_multiplier: base_dmg_mult + wpm * 0.005,
      loot_multiplier: loot_mult
    }
  end
end
