defmodule CodeMantra.Dungeon.BossEncounterEngine do
  @moduledoc """
  Manages real-time combat encounters against Issue Bosses and World Bosses.
  Evaluates developer actions, code complexity shields, and damage payouts.
  """
  use GenServer

  # 1 second combat loop tick
  @tick_interval 1000

  defstruct [
    :realm_id,
    :boss_name,
    :boss_type,
    :max_hp,
    :current_hp,
    :shield,
    :enrage_timer,
    :active_combatants,
    :timer
  ]

  # --- Client API ---

  def start_link({realm_id, boss_name, initial_hp}) do
    GenServer.start_link(__MODULE__, {realm_id, boss_name, initial_hp},
      name: via_tuple(realm_id, boss_name)
    )
  end

  def via_tuple(realm_id, boss_name) do
    {:via, Registry, {CodeMantra.DungeonRegistry, "boss:#{realm_id}:#{boss_name}"}}
  end

  @doc "Player strikes the boss with code commits or typing actions"
  def strike_boss(realm_id, boss_name, user_id, damage_payload) do
    GenServer.call(via_tuple(realm_id, boss_name), {:strike, user_id, damage_payload})
  end

  # --- Server Callbacks ---

  @impl true
  def init({realm_id, boss_name, initial_hp}) do
    timer = :timer.send_interval(@tick_interval, :boss_tick)

    state = %__MODULE__{
      realm_id: realm_id,
      boss_name: boss_name,
      boss_type: :legacy_monolith,
      max_hp: initial_hp,
      current_hp: initial_hp,
      shield: 100,
      # 60 seconds before boss casts Wipe
      enrage_timer: 60,
      active_combatants: %{},
      timer: timer
    }

    {:ok, state}
  end

  @impl true
  def handle_call(
        {:strike, user_id, %{wpm: wpm, language: lang, lines_changed: lines}},
        _from,
        state
      ) do
    # Calculate damage based on typing speed and language type advantage
    base_damage = wpm * 2 + lines * 5
    type_multiplier = language_multiplier(lang, state.boss_type)
    total_damage = round(base_damage * type_multiplier)

    # Apply damage to shield first, then HP
    {new_shield, new_hp} =
      if state.shield > 0 do
        {max(0, state.shield - total_damage), state.current_hp}
      else
        {0, max(0, state.current_hp - total_damage)}
      end

    updated_combatants =
      Map.update(state.active_combatants, user_id, total_damage, &(&1 + total_damage))

    updated_state = %{
      state
      | shield: new_shield,
        current_hp: new_hp,
        active_combatants: updated_combatants
    }

    broadcast_combat_update(updated_state)

    if new_hp == 0 do
      trigger_boss_defeat(updated_state)
      {:reply, {:ok, :boss_slain}, updated_state}
    else
      {:reply, {:ok, %{damage: total_damage, boss_hp: new_hp}}, updated_state}
    end
  end

  @impl true
  def handle_info(:boss_tick, state) do
    if state.enrage_timer <= 0 do
      # Boss casts wipe ability
      broadcast_wipe(state)
      {:stop, :normal, state}
    else
      updated_state = %{state | enrage_timer: state.enrage_timer - 1}
      broadcast_combat_update(updated_state)
      {:noreply, updated_state}
    end
  end

  # --- Helper Functions ---

  # Functional concurrency advantage
  defp language_multiplier(:elixir, :legacy_monolith), do: 1.5
  # Strict memory safety advantage
  defp language_multiplier(:rust, :legacy_monolith), do: 1.4
  defp language_multiplier(_, _), do: 1.0

  defp broadcast_combat_update(state) do
    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "boss:#{state.realm_id}:#{state.boss_name}",
      {:boss_state_updated, state}
    )
  end

  defp trigger_boss_defeat(state) do
    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "realm:#{state.realm_id}",
      {:boss_defeated, %{boss_name: state.boss_name, contributors: state.active_combatants}}
    )
  end

  defp broadcast_wipe(state) do
    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "realm:#{state.realm_id}",
      {:boss_wipe, %{boss_name: state.boss_name}}
    )
  end
end
