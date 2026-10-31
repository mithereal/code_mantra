defmodule CodeMantra.Dungeon.MonolithDrop do
  @moduledoc """
  Global background monitor running as a singleton supervisor process.
  Tracks repository technical debt across all realms and spawns World Boss
  Merge Conflicts when corruption reaches critical mass.
  """
  use GenServer, restart: :permanent
  require Logger
  alias CodeMantra.Dungeon.BossEncounterEngine

  # Check telemetry every 15 seconds
  @check_interval 15_000
  # Critical mass score triggering World Boss spawn
  @debt_threshold 850

  defstruct [:monitored_realms]

  # --- Client API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Manually registers a realm repository for technical debt monitoring"
  def monitor_realm(realm_id) do
    GenServer.call(__MODULE__, {:monitor_realm, realm_id})
  end

  @doc "Reports new technical debt increments (e.g. from static analysis or linter failures)"
  def report_debt(realm_id, debt_delta) do
    GenServer.cast(__MODULE__, {:report_debt, realm_id, debt_delta})
  end

  # --- Server Callbacks ---

  @impl true
  def init(_opts) do
    # Periodic sweep for technical debt accumulation
    :timer.send_interval(@check_interval, :sweep_debt)

    state = %__MODULE__{
      # %{realm_id => %{debt_score: int, active_boss: pid}}
      monitored_realms: %{}
    }

    Logger.info("🌋 [MONOLITH_DROP] Global technical debt monitor active.")
    {:ok, state}
  end

  @impl true
  def handle_call({:monitor_realm, realm_id}, _from, state) do
    realms = Map.put_new(state.monitored_realms, realm_id, %{debt_score: 100, active_boss: nil})
    {:reply, :ok, %{state | monitored_realms: realms}}
  end

  @impl true
  def handle_cast({:report_debt, realm_id, debt_delta}, state) do
    realms =
      Map.update(
        state.monitored_realms,
        realm_id,
        %{debt_score: 100 + debt_delta, active_boss: nil},
        fn realm ->
          %{realm | debt_score: realm.debt_score + debt_delta}
        end
      )

    {:noreply, %{state | monitored_realms: realms}}
  end

  @impl true
  def handle_info(:sweep_debt, state) do
    updated_realms =
      Enum.into(state.monitored_realms, %{}, fn {realm_id, realm_data} ->
        current_score = realm_data.debt_score

        if current_score >= @debt_threshold and is_nil(realm_data.active_boss) do
          # CRITICAL MASS REACHED: Spawn World Boss Merge Conflict!
          boss_name = "WORLD-BOSS-MERGE-CONFLICT-#{:rand.uniform(9999)}"
          initial_hp = 10_000

          case DynamicSupervisor.start_child(
                 CodeMantra.BossSupervisor,
                 {BossEncounterEngine, {realm_id, boss_name, initial_hp}}
               ) do
            {:ok, _pid} ->
              broadcast_world_boss_spawn(realm_id, boss_name, initial_hp)
              {realm_id, %{realm_data | active_boss: boss_name}}

            {:error, {:already_started, _pid}} ->
              {realm_id, realm_data}

            error ->
              Logger.error("Failed to spawn World Boss for realm #{realm_id}: #{inspect(error)}")
              {realm_id, realm_data}
          end
        else
          {realm_id, realm_data}
        end
      end)

    {:noreply, %{state | monitored_realms: updated_realms}}
  end

  # --- Helper Broadcasts ---

  defp broadcast_world_boss_spawn(realm_id, boss_name, hp) do
    Logger.warning("🚨 [WORLD BOSS SPAWN]: #{boss_name} appeared in realm #{realm_id}!")
    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "realm:#{realm_id}",
      {:world_boss_spawned,
        %{
          boss_name: boss_name,
          max_hp: hp,
          warning: "CRITICAL TECHNICAL MASS REACHED! MERGE CONFLICT OVERLORD AWAKENS!"
        }}
    )
  end
end