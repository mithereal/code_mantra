defmodule CodeMantra.Actors.BossEncounterEngine do
  @moduledoc """
  Manages Turn-Based Combat State loops for Runtime Core Threats:
  The Merge Conflict (World Boss) and The Infinite Loop (Elite Dungeon Monster).
  """
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def trigger_infinite_loop(user_id, repo_id) do
    GenServer.call(__MODULE__, {:spawn_infinite_loop, user_id, repo_id})
  end

  def execute_sigkill(user_id, encounter_id) do
    GenServer.call(__MODULE__, {:sigkill_decapitation, user_id, encounter_id})
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:spawn_infinite_loop, user_id, repo_id}, _from, state) do
    encounter_id = "loop_" <> (:crypto.strong_rand_bytes(4) |> Base.encode16())

    Logger.error("🔄 [ELITE MONSTER SPAWN]: An Infinite Loop has seized memory execution in #{repo_id}!")

    timer_ref = Process.send_after(self(), {:loop_timeout, encounter_id, user_id}, 15_000)

    encounter_state = %{
      id: encounter_id,
      user_id: user_id,
      repo_id: repo_id,
      timer_ref: timer_ref,
      status: :active,
      spawned_at: System.monotonic_time(:second)
    }

    CodeMantraWeb.Endpoint.broadcast!("developer_workspace:#{user_id}", "encounter_started", %{
      encounter_id: encounter_id,
      monster: "The Infinite Loop",
      time_limit_sec: 15,
      debuff: "Thread Lockdown & Memory Drain"
    })

    {:reply, {:ok, encounter_id}, Map.put(state, encounter_id, encounter_state)}
  end

  @impl true
  def handle_call({:sigkill_decapitation, user_id, encounter_id}, _from, state) do
    case Map.get(state, encounter_id) do
      %{status: :active, timer_ref: timer_ref} ->
        Process.cancel_timer(timer_ref)

        xp_awarded = 2800
        gold_awarded = 450
        CodeMantra.Actors.PersistenceDaemon.queue_delta(user_id, %{xp: xp_awarded, gold: gold_awarded})

        Logger.info("⚡ [SIGKILL DECAPITATION]: User #{user_id} force-terminated The Infinite Loop!")

        CodeMantraWeb.Endpoint.broadcast!("developer_workspace:#{user_id}", "encounter_cleared", %{
          encounter_id: encounter_id,
          resolution: "SIGKILL Decapitation Executed",
          rewards: %{xp: xp_awarded, gold: gold_awarded}
        })

        {:reply, {:ok, :decapitated}, Map.delete(state, encounter_id)}

      _ ->
        {:reply, {:error, :encounter_not_active}, state}
    end
  end

  @impl true
  def handle_info({:loop_timeout, encounter_id, user_id}, state) do
    if Map.has_key?(state, encounter_id) do
      Logger.error("💥 [THREAD LOCKDOWN]: User #{user_id} failed to SIGKILL in time! Memory allocation collapsed.")

      CodeMantraWeb.Endpoint.broadcast!("developer_workspace:#{user_id}", "encounter_failed", %{
        encounter_id: encounter_id,
        reason: "Memory Allocation Overflow & Thread Crash"
      })
    end

    {:noreply, Map.delete(state, encounter_id)}
  end
end