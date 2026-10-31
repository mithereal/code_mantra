defmodule CodeMantra.Dungeon.BossEncounterEngine do
  @moduledoc """
  Unified Boss Encounter Engine. Spawns per-realm GenServers via Registry,
  combining telemetry damage calculations, dynamic syntax vulnerability windows,
  and enrage mechanics.
  """
  use GenServer, restart: :transient
  require Logger

  @tick_interval 1_000

  defstruct [
    :realm_id,
    :encounter_id,
    :boss_name,
    :boss_type,
    :max_hp,
    :current_hp,
    :shield,
    :enrage_timer,
    :phase,
    :vulnerability_window,
    :aggro_table,
    :status,
    :timer_ref
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

  @doc "Strikes the boss using code telemetry or explicit spell payloads."
  def strike(realm_id, boss_name, player_id, cast_payload) do
    GenServer.call(via_tuple(realm_id, boss_name), {:strike, player_id, cast_payload})
  end

  def get_state(realm_id, boss_name) do
    GenServer.call(via_tuple(realm_id, boss_name), :get_state)
  end

  # --- Server Callbacks ---

  @impl true
  def init({realm_id, boss_name, initial_hp}) do
    timer_ref = Process.send_after(self(), :tick, @tick_interval)

    state = %__MODULE__{
      realm_id: realm_id,
      encounter_id: "ENC-" <> Ecto.UUID.generate(),
      boss_name: boss_name,
      boss_type: :legacy_monolith,
      max_hp: initial_hp,
      current_hp: initial_hp,
      shield: 100,
      enrage_timer: 60,
      phase: 1,
      vulnerability_window: :pure_functional,
      aggro_table: %{},
      status: :active,
      timer_ref: timer_ref
    }

    Logger.info("⚔️ [BOSS_ENCOUNTER] Spawned #{boss_name} for realm #{realm_id} (HP: #{initial_hp})")
    broadcast_state(state)
    {:ok, state}
  end

  @impl true
  def handle_call({:strike, player_id, payload}, _from, %{status: :active} = state) do
    wpm = Map.get(payload, :wpm, 0)
    lines = Map.get(payload, :lines_changed, 0)
    paradigm = Map.get(payload, :paradigm, :generic)
    base_spell_damage = Map.get(payload, :damage, 0)

    # 1. Base Damage Calculation (Telemetry + Spell Base)
    raw_damage = (wpm * 2 + lines * 5) + base_spell_damage

    # 2. Paradigm Vulnerability Multiplier
    multiplier = if paradigm == state.vulnerability_window, do: 2.5, else: 1.0
    total_damage = round(raw_damage * multiplier)

    # 3. Shield & HP Absorption Logic
    {new_shield, new_hp} =
      if state.shield > 0 do
        {max(0, state.shield - total_damage), state.current_hp}
      else
        {0, max(0, state.current_hp - total_damage)}
      end

    updated_aggro = Map.update(state.aggro_table, player_id, total_damage, &(&1 + total_damage))

    updated_state = %{
      state
    | shield: new_shield,
      current_hp: new_hp,
      aggro_table: updated_aggro
    }

    broadcast_state(updated_state)

    if new_hp == 0 do
      final_state = %{updated_state | status: :defeated}
      trigger_boss_defeat(final_state)
      {:stop, :normal, {:ok, :boss_slain}, final_state}
    else
      {:reply, {:ok, %{damage: total_damage, boss_hp: new_hp, shield: new_shield}}, updated_state}
    end
  end

  @impl true
  def handle_call({:strike, _player_id, _payload}, _from, state) do
    {:reply, {:error, :boss_not_active}, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:tick, %{status: :active} = state) do
    if state.enrage_timer <= 0 do
      broadcast_wipe(state)
      {:stop, :normal, %{state | status: :wiped}}
    else
      # Rotate vulnerability window randomly on tick
      windows = [:pure_functional, :low_level_pointer, :smart_contract_state, :async_pipeline]
      next_vuln = Enum.random(windows)

      updated_state = %{
        state
      | enrage_timer: state.enrage_timer - 1,
        vulnerability_window: next_vuln
      }

      broadcast_state(updated_state)
      timer_ref = Process.send_after(self(), :tick, @tick_interval)
      {:noreply, %{updated_state | timer_ref: timer_ref}}
    end
  end

  @impl true
  def handle_info(:tick, state), do: {:noreply, state}

  # --- Internal Helpers ---

  defp broadcast_state(state) do
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
      {:boss_defeated, %{boss_name: state.boss_name, contributors: state.aggro_table}}
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