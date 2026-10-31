defmodule CodeMantra.Actors.MonolithDrop do
  @moduledoc """
  Actor 6: MONOLITH DROP (World Boss Event Daemon).
  Manages real-time world boss encounters, global HP tracking, periodic damage ticks,
  and dynamic loot drop distributions when the Monolith core is breached.
  """
  use GenServer
  require Logger

  @tick_interval 5_000 # 5-second broadcast tick

  # --- Client API ---
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def trigger_drop(boss_id, initial_hp \\ 100_000) do
    GenServer.call(__MODULE__, {:spawn_boss, boss_id, initial_hp})
  end

  def register_strike(player_id, damage) do
    GenServer.cast(__MODULE__, {:strike, player_id, damage})
  end

  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  # --- Server Callbacks ---
  @impl true
  def init(_opts) do
    state = %{
      active_boss: nil,
      current_hp: 0,
      max_hp: 0,
      contributors: %{},
      status: :dormant
    }

    Logger.info("[MONOLITH_DROP] World Boss Event Daemon initialized.")
    {:ok, state}
  end

  @impl true
  def handle_call({:spawn_boss, boss_id, initial_hp}, _from, state) do
    Logger.info("🌋 [MONOLITH_DROP] WORLD BOSS SPAWNED: #{boss_id} with #{initial_hp} HP!")

    new_state = %{
      active_boss: boss_id,
      current_hp: initial_hp,
      max_hp: initial_hp,
      contributors: %{},
      status: :active
    }

    schedule_tick()
    broadcast_world_state(new_state)

    {:reply, {:ok, boss_id}, new_state}
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:strike, player_id, damage}, %{status: :active} = state) do
    new_hp = max(0, state.current_hp - damage)
    updated_contributors = Map.update(state.contributors, player_id, damage, &(&1 + damage))

    new_state = %{state | current_hp: new_hp, contributors: updated_contributors}

    if new_hp == 0 do
      Logger.info("🏆 [MONOLITH_DROP] World Boss #{state.active_boss} has been DEFEATED! Distributing spoils...")
      distribute_spoils(new_state.contributors)
      {:noreply, %{new_state | status: :defeated}}
    else
      {:noreply, new_state}
    end
  end

  @impl true
  def handle_cast({:strike, _player_id, _damage}, state) do
    # Ignore strikes when no boss is active
    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, %{status: :active} = state) do
    broadcast_world_state(state)
    schedule_tick()
    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, state) do
    {:noreply, state}
  end

  # --- Internal Helpers ---
  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval)
  end

  defp broadcast_world_state(state) do
    CodeMantraWeb.Endpoint.broadcast!("world:monolith", "boss_status_update", %{
      boss_id: state.active_boss,
      current_hp: state.current_hp,
      max_hp: state.max_hp,
      status: state.status
    })
  end

  defp distribute_spoils(contributors) do
    Enum.each(contributors, fn {player_id, total_damage} ->
      loot_multiplier = max(1.0, total_damage / 500.0)
      bonus_gold = trunc(50 * loot_multiplier)
      bonus_xp = trunc(200 * loot_multiplier)

      Logger.debug("[MONOLITH_DROP] Rewarding User #{player_id}: #{bonus_xp} XP, #{bonus_gold} Gold.")

      # Broadcast personal victory reward via PubSub
      Phoenix.PubSub.broadcast(
        CodeMantra.PubSub,
        "player:#{player_id}",
        {:monolith_victory, %{xp: bonus_xp, gold: bonus_gold}}
      )
    end)
  end
end