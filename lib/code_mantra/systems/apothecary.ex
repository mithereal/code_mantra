defmodule CodeMantra.Systems.Apothecary do
  @moduledoc """
  The Runtime Apothecary item shop ledger. Manages gold transactions, mastery tier
  prerequisites, and runtime status effects for consumable developer items.
  """
  require Logger

  @catalog %{
    "caffeine_tincture" => %{
      name: "Caffeine Overclock Tincture",
      cost: 150,
      min_level: 1,
      effect: :flow_state_boost,
      duration_min: 15,
      description: "Instantly triggers Flow State (1.5x XP Modifier) for 15 minutes.",
      side_effect: "Jittery Syntax: +20% backspace character deletion penalty upon expiration."
    },
    "gc_elixir" => %{
      name: "Elixir of Garbage Collection",
      cost: 300,
      min_level: 6,
      effect: :purge_memory_leaks,
      description: "Cures all active memory leak status ailments. Converts flushed chunks to gold."
    },
    "pipeline_salt" => %{
      name: "Pipeline Defibrillator Salt",
      cost: 500,
      min_level: 16,
      effect: :purge_ci_shame,
      description: "Instantly purges 'Shame of the Red Build' CI penalty without running validation."
    },
    "hot_reload_catalyst" => %{
      name: "Hot-Reload Catalyst",
      cost: 1200,
      min_level: 31,
      effect: :freeze_buffer_xp,
      charges: 3,
      description: "Freezes uncommitted buffer XP upon build error instead of wiping progress."
    }
  }

  def catalog, do: @catalog

  def purchase(user_id, item_id, user_level, current_gold) do
    case Map.get(@catalog, item_id) do
      nil ->
        {:error, :item_not_found}

      item when user_level < item.min_level ->
        {:error, {:insufficient_mastery, required: item.min_level}}

      item when current_gold < item.cost ->
        {:error, :insufficient_gold}

      item ->
        remaining_gold = current_gold - item.cost
        CodeMantra.Actors.PersistenceDaemon.queue_delta(user_id, %{gold: -item.cost})

        Logger.info("🧪 [APOTHECARY] User #{user_id} acquired #{item.name} for #{item.cost} Gold.")
        {:ok, item, remaining_gold}
    end
  end
end