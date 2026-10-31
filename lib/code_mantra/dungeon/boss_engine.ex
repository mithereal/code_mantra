defmodule CodeMantra.Dungeon.BossEngine do
  @moduledoc """
  Transforms incoming GitHub Webhook PR payloads into multi-phase
  boss fight encounters with scaling HP, armor, and phase triggers.
  """

  @type boss_encounter :: %{
          boss_id: String.t(),
          boss_name: String.t(),
          total_hp: integer(),
          current_hp: integer(),
          armor: integer(),
          phase: :phase_1_overmind | :phase_2_refactor_adds | :phase_3_merge_ready,
          is_enraged: boolean(),
          rewards: map()
        }

  @doc """
  Constructs a Boss Encounter struct from a parsed GitHub Pull Request webhook payload.
  """
  @spec manifest_boss(map()) :: {:ok, boss_encounter()}
  def manifest_boss(pr_payload) do
    additions = Map.get(pr_payload, "additions", 0)
    deletions = Map.get(pr_payload, "deletions", 0)
    changed_files = Map.get(pr_payload, "changed_files", 1)
    pr_title = Map.get(pr_payload, "title", "Refactor Monolith")
    pr_id = Map.get(pr_payload, "node_id", "PR_0000")

    base_hp = calculate_hp(additions, deletions, changed_files)
    armor_value = min(round(changed_files * 3.5), 75)

    boss_name = generate_boss_title(pr_title, additions)

    encounter = %{
      boss_id: pr_id,
      boss_name: boss_name,
      total_hp: base_hp,
      current_hp: base_hp,
      armor: armor_value,
      phase: :phase_1_overmind,
      is_enraged: false,
      rewards: %{
        exp: round(base_hp * 0.8),
        loot_tier: determine_loot_tier(base_hp)
      }
    }

    {:ok, encounter}
  end

  @doc """
  Processes a review comment or CI check update event, adjusting boss phases or enrage state.
  """
  def process_event(encounter, :ci_failed) do
    # CI Build Failure triggers Boss Enrage state
    %{encounter | is_enraged: true}
  end

  def process_event(encounter, :review_comment_added) do
    # Review comments spawn Phase 2 refactor add-minions
    current_phase =
      if encounter.phase == :phase_1_overmind, do: :phase_2_refactor_adds, else: encounter.phase

    %{encounter | phase: current_phase, armor: encounter.armor + 5}
  end

  def process_event(encounter, :ci_passed) do
    # Resolving CI clears enrage and transitions towards final merge phase
    %{encounter | is_enraged: false, phase: :phase_3_merge_ready}
  end

  defp calculate_hp(additions, deletions, files) do
    raw_hp = round(additions * 2.5 + deletions * 1.2 + files * 50)
    # Minimum 100 HP boss threshold
    max(raw_hp, 100)
  end

  defp generate_boss_title(title, additions) do
    prefix =
      cond do
        additions > 1000 -> "The Monolithic Behemoth"
        additions > 500 -> "The Legacy Colossus"
        additions > 100 -> "The Refactor Sentinel"
        true -> "Micro-Diff Imp"
      end

    "#{prefix}: #{title}"
  end

  defp determine_loot_tier(hp) do
    cond do
      hp >= 2500 -> :legendary_vault
      hp >= 1000 -> :epic_chest
      true -> :standard_pouch
    end
  end
end
