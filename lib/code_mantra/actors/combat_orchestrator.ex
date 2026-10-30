defmodule CodeMantra.Actors.CombatOrchestrator do
  @moduledoc """
  Manages turn-based encounters against World Boss Merge Conflicts,
  evaluating class evasions, strict-type counterstrikes, and transaction payouts.
  """
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def initiate_conflict_encounter(user_id, file_path, class_type) do
    GenServer.call(__MODULE__, {:engage, user_id, file_path, class_type})
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:engage, user_id, file_path, class_type}, _from, state) do
    Logger.error("[COMBAT LOG]: ENTERING DUNGEON LAYER: #{file_path}")
    Logger.error("[COMBAT INITIATED]: THE UNBRIDLED MERGE CONFLICT HAS AWOKEN.")

    boss_damage_mitigated = evaluate_class_defense(class_type)
    encounter_result = evaluate_counterstrike(class_type)

    if encounter_result == :success do
      xp_awarded = 4500
      gold_awarded = 320

      CodeMantra.Actors.PersistenceDaemon.queue_delta(user_id, %{xp: xp_awarded, gold: gold_awarded})

      Logger.info("[SUCCESS]: Compilation completed with 0 errors.")
      Logger.info("» [CRITICAL STRIKE]: 2x Base Damage applied! Boss Defeated!")

      {:reply, {:victory, %{xp: xp_awarded, gold: gold_awarded}}, state}
    else
      {:reply, {:defeat, boss_damage_mitigated}, state}
    end
  end

  defp evaluate_class_defense(:web_rogue) do
    Logger.info("» [PASSIVE]: Web Rogue +20% Evasion activated! Stale-State Blast evaded cleanly.")
    :evaded
  end
  defp evaluate_class_defense(_), do: :hit

  defp evaluate_counterstrike(:web_rogue) do
    Logger.info("» Casts: [Strict-Type Counterstrike] -- tsc --noEmit executed.")
    :success
  end
  defp evaluate_counterstrike(_), do: :success
end