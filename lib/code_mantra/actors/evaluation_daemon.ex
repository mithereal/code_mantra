defmodule CodeMantra.Actors.EvaluationDaemon do
  @moduledoc """
  Actor 2: EVALUATION DAEMON.
  Procedurally synthesizes royal titles, dynamic prefixes, language syntaxes,
  impact legacies, and unbounded rank badges based on real-time code telemetry.
  """
  use GenServer
  require Logger

  alias CodeMantra.SharedUtils

  # --- Client API ---
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def evaluate_ast(user_id, batch_payload) do
    GenServer.cast(__MODULE__, {:analyze, user_id, batch_payload})
  end

  # --- GenServer Callbacks ---
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:analyze, user_id, %{"buffer_content" => content} = payload}, state) do
    lang = Map.get(payload, "language", "unknown") |> String.downcase()
    file_ext = Map.get(payload, "file_extension", "") |> String.downcase()

    complexity_score = SharedUtils.calculate_cyclomatic_complexity(content)
    paradigm = classify_polyglot_paradigm(lang, file_ext, content)

    commits_per_day = payload["commits_per_day"] || 10.0
    avg_lines_per_commit = payload["avg_lines_per_commit"] || 30.0
    legacy_ratio = SharedUtils.calculate_legacy_ratio(content, payload)
    total_xp = payload["cumulative_xp"] || 150

    title_info =
      generate_procedural_title(
        commits_per_day,
        avg_lines_per_commit,
        paradigm,
        legacy_ratio,
        total_xp
      )

    rank_info = generate_procedural_rank(total_xp, complexity_score)

    Logger.info("""
    // [SYSTEM INFO]: EVALUATION_DAEMON Proclamation...
    // The King witnesses an ascension to [Rank: #{rank_info.rank_name} (#{rank_info.tier_badge})].
    // ROYAL TITLE: >>> #{String.upcase(title_info.title)} <<<
    """)

    evaluated_payload =
      Map.merge(payload, %{
        "complexity" => complexity_score,
        "paradigm" => paradigm,
        "royal_title" => title_info.title,
        "title_hash_id" => title_info.title_hash_id,
        "legacy_ratio" => legacy_ratio,
        "rank_name" => rank_info.rank_name,
        "tier_badge" => rank_info.tier_badge,
        "level" => rank_info.level
      })

    # Forward downstream to ProgressionBalancer (Actor 3)
    CodeMantra.Actors.ProgressionBalancer.process_telemetry(user_id, evaluated_payload)

    # Sync state checkpoint with PersistenceDaemon (Actor 4)
    CodeMantra.Actors.PersistenceDaemon.queue_delta(user_id, %{
      title_hash: title_info.title_hash_id,
      level: rank_info.level
    })

    # Trigger rank archival for guild inheritance if elite tier reached
    CodeMantra.Actors.PersistenceDaemon.archive_rank(user_id, evaluated_payload)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:analyze, user_id, payload}, state) do
    CodeMantra.Actors.ProgressionBalancer.process_telemetry(user_id, payload)
    {:noreply, state}
  end

  # --- Procedural Rank & Dynamic Name Synthesizer ---
  defp generate_procedural_rank(xp, complexity) do
    score = xp + complexity * 20
    level = max(1, div(score, 100))

    :rand.seed(:exsss, {score + 99, score + 33, score + 7})

    adjectives = [
      "Void", "Arcane", "Mythic", "Astral", "Quantum", "Iron", "Shadow", "Solar",
      "Ethereal", "Prime", "Cyber", "Core", "Abyssal", "Hyper", "Binary", "Recursive",
      "Atomic", "Neon", "Spectral", "Celestial"
    ]

    nouns = [
      "Weaver", "Architect", "Scribe", "Knight", "Sorcerer", "Smith", "Daemon",
      "Sovereign", "Oracle", "Coder", "Engine", "Ghost", "Lord", "Warden", "Stalker",
      "Alchemist", "Reaper", "Mage", "Sage"
    ]

    rank_name = "#{Enum.random(adjectives)} #{Enum.random(nouns)}"

    badge =
      cond do
        score >= 50_000 -> "OMEGA"
        score >= 35_000 -> "X+"
        score >= 25_000 -> "X"
        score >= 18_000 -> "SSS+"
        score >= 12_000 -> "SSS"
        score >= 8_500 -> "SS+"
        score >= 6_000 -> "SS"
        score >= 4_000 -> "S+"
        score >= 2_500 -> "S"
        score >= 1_500 -> "A+"
        score >= 1_000 -> "A"
        score >= 600 -> "B+"
        score >= 350 -> "B"
        score >= 200 -> "C+"
        score >= 100 -> "C"
        true -> "D"
      end

    %{rank_name: rank_name, tier_badge: badge, level: level}
  end

  defp generate_procedural_title(commits_per_day, avg_lines, paradigm, legacy_ratio, total_xp) do
    p_type =
      cond do
        commits_per_day >= 8 and avg_lines <= 50 -> :fast_small
        avg_lines >= 500 -> :slow_massive
        true -> :balanced
      end

    seed = trunc(commits_per_day * avg_lines * 13 + legacy_ratio * 1000 + total_xp)
    :rand.seed(:exsss, {seed, seed + 1, seed + 2})

    prefix = synthesize_prefix(p_type)
    syntax = synthesize_syntax(paradigm)
    legacy = synthesize_legacy(legacy_ratio >= 0.6)

    full_title = "The #{prefix} #{syntax} #{legacy}"

    hash_digest = :crypto.hash(:md5, full_title) |> Base.encode16(case: :lower)
    {int_val, _} = Integer.parse(String.slice(hash_digest, 0, 8), 16)
    title_hash = rem(int_val, 1_000_000)

    %{title: full_title, title_hash_id: title_hash}
  end

  defp synthesize_prefix(:fast_small),
       do: Enum.random(["Iterative", "Flashing", "Restless", "Spry", "Asynchronous", "Callback"])

  defp synthesize_prefix(:slow_massive),
       do: Enum.random(["Monolithic", "Patient", "Cataclysmic", "Unyielding", "Titan-Scale"])

  defp synthesize_prefix(:balanced),
       do: Enum.random(["Steady", "Measured", "Architectural", "Harmonious"])

  defp synthesize_syntax(:functional),
       do: Enum.random(["Lambda", "Immutability", "Recursion", "Monad", "Pure-State"])

  defp synthesize_syntax(:low_level),
       do: Enum.random(["Pointer", "Registry", "Pointer-Forge", "Kernel", "Byte-Smith"])

  defp synthesize_syntax(:smart_contract),
       do: Enum.random(["Contract", "State", "Gas-Lord", "Immutable"])

  defp synthesize_syntax(:devops_infra),
       do: Enum.random(["Cluster", "Pipeline", "Provisioner", "Container-Wraith"])

  defp synthesize_syntax(:data_query),
       do: Enum.random(["Query-Master", "Schema-Weaver", "Relation-Smith"])

  defp synthesize_syntax(:shell_script),
       do: Enum.random(["Bash-Lord", "Script-Runner", "Pipe-Master"])

  defp synthesize_syntax(:oop), do: Enum.random(["Polymorphic", "Inheritor", "Encapsulator"])

  defp synthesize_syntax(:web_rogue),
       do: Enum.random(["Callback", "Shadow-Thread", "Strict-Type"])

  defp synthesize_syntax(: