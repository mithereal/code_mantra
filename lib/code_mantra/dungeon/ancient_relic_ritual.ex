defmodule CodeMantra.Dungeon.AncientRelicRitual do
  @moduledoc """
  Manages Ancient Relic rituals (Fortran, Lisp, Algol), calculating
  massive team-wide XP multipliers and enforcing syntax corruption hazards.
  """

  @relics %{
    lisp: %{name: "Lisp (The Macro Weaver)", multiplier: 4.0, hazard_threshold: 0.85},
    fortran: %{name: "Fortran (The Numeric Core)", multiplier: 3.5, hazard_threshold: 0.80},
    algol: %{name: "Algol (The Block Structure)", multiplier: 3.0, hazard_threshold: 0.75}
  }

  @doc """
  Invokes an ancient ritual for a given relic language, evaluating test coverage
  against corruption hazards to determine whether a Blessing or a Curse is bestowed.
  """
  @spec invoke_ritual(atom(), integer(), float()) :: {:blessing, map()} | {:curse, map()} | {:error, term()}
  def invoke_ritual(relic_type, lines_written, test_coverage_pct) do
    case Map.get(@relics, relic_type) do
      nil ->
        {:error, :unknown_ancient_artifact}

      relic ->
        if test_coverage_pct >= relic.hazard_threshold do
          # Ritual Successful: Elder Beings bestow massive multipliers
          xp_gain = round(lines_written * relic.multiplier * 25)

          {:blessing,
            %{
              relic: relic.name,
              xp_awarded: xp_gain,
              team_flow_buff: relic.multiplier,
              message:
                "The Elder Beings accept your sacrifice. The realm thrives on ancient wisdom."
            }}
        else
          # Ritual Corrupted: Syntax anomaly triggers a technical debt curse
          penalty_points = round(lines_written * 15)

          {:curse,
            %{
              relic: relic.name,
              corruption_penalty: penalty_points,
              status: :syntax_anomaly_quarantine,
              message:
                "Inadequate test coverage has awakened a Syntax Corruption Hazard! Code quarantined."
            }}
        end
    end
  end
end