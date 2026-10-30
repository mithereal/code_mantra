defmodule CodeMantra.Actors.ProgressionBalancer do
  @moduledoc """
  Actor 3: PROGRESSION & BALANCE ENGINE.
  Validates incoming IDE telemetry buffers using Shannon Entropy anti-cheat heuristics,
  computes WPM cadence and cyclomatic complexity scaling, awards XP and Gold Shards,
  and syncs state deltas with PersistenceDaemon (Actor 4).
  """
  use GenServer
  require Logger

  # --- Client API ---
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def process_telemetry(user_id, payload) do
    GenServer.cast(__MODULE__, {:evaluate, user_id, payload})
  end

  def evaluate_buffer(user_id, payload) do
    GenServer.cast(__MODULE__, {:evaluate_buffer, user_id, payload})
  end

  # --- GenServer Callbacks ---
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:evaluate_buffer, user_id, payload}, state) do
    handle_evaluation(user_id, payload)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:evaluate, user_id, payload}, state) do
    handle_evaluation(user_id, payload)
    {:noreply, state}
  end

  # --- Core Evaluation Pipeline ---
  defp handle_evaluation(user_id, payload) do
    case validate_telemetry(payload) do
      {:ok, :human_telemetry, wpm} ->
        complexity = payload["complexity"] || 1
        xp_earned = trunc(wpm * 1.5) + (complexity * 2)
        gold_earned = max(1, trunc(complexity / 2))

        Logger.info("[PROGRESSION_BALANCER] Awarding #{xp_earned} XP and #{gold_earned} Shards to User #{user_id} (WPM: #{wpm}, Complexity: #{complexity})")

        # 1. Broadcast real-time XP gain over PubSub
        Phoenix.PubSub.broadcast(
          CodeMantra.PubSub,
          "player:#{user_id}",
          {:xp_gained, %{xp: xp_earned, gold: gold_earned, wpm: wpm}}
        )

        # 2. Queue state checkpoint with PersistenceDaemon (Actor 4)
        CodeMantra.Actors.PersistenceDaemon.queue_delta(user_id, %{xp: xp_earned, gold: gold_earned})

      {:ok, :llm_assisted_paste, line_count} ->
        familiar_xp = line_count * 3
        Logger.info("[PROGRESSION_BALANCER] AI Burst/Paste detected for User #{user_id}. Awarding #{familiar_xp} Familiar XP.")

        Phoenix.PubSub.broadcast(
          CodeMantra.PubSub,
          "player:#{user_id}",
          {:familiar_xp_gained, %{xp: familiar_xp, lines: line_count}}
        )

      {:reject, :autogrammar_anomaly, reason} ->
        Logger.warning("[ANTI-CHEAT ALERT] Rejected telemetry from User #{user_id}: #{reason}")
    end
  end

  # --- Telemetry Anti-Cheat Heuristics ---
  defp validate_telemetry(%{"buffer_content" => content, "delta_time_ms" => delta_ms} = payload) do
    char_count = String.length(content)
    wpm = payload["wpm_cadence"] || 0.0

    cond do
      char_count > 100 and delta_ms < 15 ->
        lines = max(1, length(String.split(content, "\n")))
        {:ok, :llm_assisted_paste, lines}

      char_count >= 10 and calculate_entropy(content) < 1.2 ->
        {:reject, :autogrammar_anomaly, "Low character variance detected (macro / key-holding)"}

      wpm > 280.0 ->
        {:reject, :autogrammar_anomaly, "Typing cadence exceeds physical human limits (>280 WPM)"}

      true ->
        {:ok, :human_telemetry, wpm}
    end
  end

  defp validate_telemetry(_), do: {:reject, :autogrammar_anomaly, "Malformed or missing telemetry payload parameters"}

  @doc """
  Calculates Shannon Entropy (H) to flag repetitive macro spam and automated key simulation.
  """
  defp calculate_entropy(""), do: 0.0
  defp calculate_entropy(text) do
    len = String.length(text)

    text
    |> String.graphemes()
    |> Enum.frequencies()
    |> Enum.reduce(0.0, fn {_char, count}, acc ->
      p = count / len
      acc - p * :math.log2(p)
    end)
  end
end