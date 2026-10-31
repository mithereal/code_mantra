defmodule CodeMantra.Actors.ProgressionBalancer do
  @moduledoc """
  Actor 3: PROGRESSION & BALANCE ENGINE.
  Validates incoming telemetry buffers using Shannon Entropy anti-cheat heuristics,
  awards XP and Gold Shards, and syncs state deltas with PersistenceDaemon.
  """
  use GenServer
  require Logger

  alias CodeMantra.SharedUtils

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def process_telemetry(user_id, payload) do
    GenServer.cast(__MODULE__, {:evaluate, user_id, payload})
  end

  def evaluate_buffer(user_id, payload) do
    GenServer.cast(__MODULE__, {:evaluate, user_id, payload})
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_cast({:evaluate, user_id, payload}, state) do
    case SharedUtils.validate_telemetry(payload) do
      {:ok, :human_telemetry, wpm} ->
        complexity = payload["complexity"] || 1
        xp_earned = trunc(wpm * 1.5) + complexity * 2
        gold_earned = max(1, trunc(complexity / 2))

        Logger.info(
          "[PROGRESSION_BALANCER] Awarding #{xp_earned} XP and #{gold_earned} Shards to User #{user_id} (WPM: #{wpm}, Complexity: #{complexity})"
        )

        Phoenix.PubSub.broadcast(
          CodeMantra.PubSub,
          "player:#{user_id}",
          {:xp_gained, %{xp: xp_earned, gold: gold_earned, wpm: wpm}}
        )

        CodeMantra.Actors.PersistenceDaemon.queue_delta(user_id, %{
          xp: xp_earned,
          gold: gold_earned
        })

      {:ok, :llm_assisted_paste, line_count} ->
        familiar_xp = line_count * 3

        Logger.info(
          "[PROGRESSION_BALANCER] AI Burst/Paste detected for User #{user_id}. Awarding #{familiar_xp} Familiar XP."
        )

        Phoenix.PubSub.broadcast(
          CodeMantra.PubSub,
          "player:#{user_id}",
          {:familiar_xp_gained, %{xp: familiar_xp, lines: line_count}}
        )

      {:reject, :autogrammar_anomaly, reason} ->
        Logger.warning("[ANTI-CHEAT ALERT] Rejected telemetry from User #{user_id}: #{reason}")
    end

    {:noreply, state}
  end
end
