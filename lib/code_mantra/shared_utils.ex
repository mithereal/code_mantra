defmodule CodeMantra.SharedUtils do
  @moduledoc """
  Shared utilities for telemetry validation, Shannon entropy, cyclomatic complexity,
  and combat calculations across CodeMantra GenServers and domain logic.
  """

  @doc """
  Calculates Shannon Entropy (H) to flag repetitive macro spam and key-holding anti-cheat anomalies.
  """
  def calculate_entropy(""), do: 0.0

  def calculate_entropy(text) do
    len = String.length(text)

    text
    |> String.graphemes()
    |> Enum.frequencies()
    |> Enum.reduce(0.0, fn {_char, count}, acc ->
      p = count / len
      acc - p * :math.log2(p)
    end)
  end

  @doc """
  Calculates cyclomatic complexity based on branching keywords and control flow constructs.
  """
  def calculate_cyclomatic_complexity(code) do
    branches =
      ~r/\b(if|else|elif|elseif|case|cond|match|switch|for|while|do|catch|rescue|except|and|or|&&|\|\||fn|def|func|function|class|select|where|resource|pipeline)\b/

    Regex.scan(branches, code) |> (length() + 1)
  end

  @doc """
  Validates incoming IDE telemetry buffers against anti-cheat heuristics.
  """
  def validate_telemetry(%{"buffer_content" => content, "delta_time_ms" => delta_ms} = payload) do
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

  def validate_telemetry(_),
    do: {:reject, :autogrammar_anomaly, "Malformed or missing telemetry payload parameters"}

  @doc """
  Calculates technical debt ratio based on TODO/FIXME/HACK annotations.
  """
  def calculate_legacy_ratio(_content, %{"legacy_code_ratio" => ratio}) when is_number(ratio),
    do: ratio

  def calculate_legacy_ratio(content, _payload) do
    debt_keywords = ~r/\b(TODO|FIXME|HACK|LEGACY|DEPRECATED|REFAC)\b/i
    matches = Regex.scan(debt_keywords, content) |> length()
    base_ratio = if matches > 0, do: 0.65, else: 0.35
    min(1.0, max(0.0, base_ratio + matches * 0.05))
  end
end
