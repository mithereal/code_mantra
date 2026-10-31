defmodule CodeMantra.Actors.BossEncounterEngine do
  @moduledoc """
  Actor 7: BOSS ENCOUNTER ENGINE.
  Manages real-time multi-phase boss encounters, dynamic threat/aggro tables,
  syntax vulnerability windows, and raid-wide cast resolution.
  """
  use GenServer
  require Logger

  @tick_interval 2_000

  # --- Client API ---
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def engage_boss(encounter_id, boss_profile) do
    GenServer.call(__MODULE__, {:engage, encounter_id, boss_profile})
  end

  def submit_cast(player_id, spell_payload) do
    GenServer.cast(__MODULE__, {:submit_cast, player_id, spell_payload})
  end

  def get_encounter_state do
    GenServer.call(__MODULE__, :get_state)
  end

  # --- Server Callbacks ---
  @impl true
  def init(_opts) do
    state = %{
      encounter_id: nil,
      boss_name: nil,
      current_hp: 0,
      max_hp: 0,
      phase: 1,
      aggro_table: %{},
      vulnerability_window: :none,
      status: :idle
    }

    Logger.info("[BOSS_ENCOUNTER_ENGINE] Initialized and waiting for raid engagement.")
    {:ok, state}
  end

  @impl true
  def handle_call({:engage, encounter_id, %{name: name, hp: hp} = profile}, _from, state) do
    Logger.info("⚔️ [BOSS_ENCOUNTER_ENGINE] Encounter engaged: #{name} (HP: #{hp}) [ID: #{encounter_id}]")

    new_state = %{
      encounter_id: encounter_id,
      boss_name: name,
      current_hp: hp,
      max_hp: hp,
      phase: Map.get(profile, :phase, 1),
      aggro_table: %{},
      vulnerability_window: Map.get(profile, :initial_vuln, :pure_functional),
      status: :active
    }

    schedule_tick()
    broadcast_encounter(new_state)

    {:reply, {:ok, encounter_id}, new_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:submit_cast, player_id, spell_payload}, %{status: :active} = state) do
    paradigm = Map.get(spell_payload, :paradigm) || Map.get(spell_payload, "paradigm", :generic)
    damage = Map.get(spell_payload, :damage) || Map.get(spell_payload, "damage", 50)

    # Check if cast matches current boss vulnerability window for critical multiplier
    multiplier = if paradigm == state.vulnerability_window, do: 2.5, else: 1.0
    final_damage = trunc(damage * multiplier)

    new_hp = max(0, state.current_hp - final_damage)
    updated_aggro = Map.update(state.aggro_table, player_id, final_damage, &(&1 + final_damage))

    Logger.info("⚡ [BOSS_ENCOUNTER_ENGINE] User #{player_id} hit #{state.boss_name} with #{paradigm} for #{final_damage} damage! (Boss HP: #{new_hp}/#{state.max_hp})")

    new_state = %{state | current_hp: new_hp, aggro_table: updated_aggro}

    if new_hp == 0 do
      Logger.info("🏆 [BOSS_ENCOUNTER_ENGINE] Raid Boss #{state.boss_name} VANQUISHED!")
      broadcast_encounter(%{new_state | status: :defeated})
      {:noreply, %{new_state | status: :defeated}}
    else
      broadcast_encounter(new_state)
      {:noreply, new_state}
    end
  end

  @impl true
  def handle_cast({:submit_cast, _player_id, _spell_payload}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, %{status: :active} = state) do
    # Rotate vulnerability windows periodically to test multi-paradigm mastery
    windows = [:pure_functional, :low_level_pointer, :smart_contract_state, :async_pipeline]
    next_vuln = Enum.random(windows)

    new_state = %{state | vulnerability_window: next_vuln}
    broadcast_encounter(new_state)

    schedule_tick()
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:tick, state) do
    {:noreply, state}
  end

  # --- Internal Helpers ---
  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval)
  end

  defp broadcast_encounter(state) do
    CodeMantraWeb.Endpoint.broadcast!("boss:raid", "encounter_state_changed", %{
      boss_name: state.boss_name,
      current_hp: state.current_hp,
      max_hp: state.max_hp,
      phase: state.phase,
      vulnerability_window: state.vulnerability_window,
      status: state.status
    })
  end
end