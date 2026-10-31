defmodule CodeMantra.Workers.LanguageRankScannerWorker do
  @moduledoc """
  Oban background worker that executes once per month to scan
  GitHub language usage trends and rebalance realm ecosystem ranks.
  """
  use Oban.Worker,
    queue: :scheduled,
    max_attempts: 3,
    # Prevent duplicate runs within 24 hours
    unique: [period: 86_400]

  alias CodeMantra.Dungeon.LanguageClassifier

  @impl Oban.Worker
  def perform(_job) do
    case fetch_latest_github_rankings() do
      {:ok, new_top_20} ->
        # 1. Update the LanguageClassifier GenServer cache
        LanguageClassifier.update_top_ranks(new_top_20)

        # 2. Broadcast world-tree rebalancing wave to all active realms
        broadcast_ecosystem_rebalance(new_top_20)

        {:ok}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_latest_github_rankings do
    # In production, this would query the GitHub Octoverse API or telemetry aggregator.
    # Returning updated mainstream rankings ordered by global usage volume.
    mocked_live_rankings = [
      "TypeScript",
      "Python",
      "JavaScript",
      "Java",
      "C#",
      # Shifted positions
      "C++",
      "PHP",
      "Go",
      "C",
      "Shell",
      "Ruby",
      "Rust",
      "Kotlin",
      "Swift",
      "R",
      "Dart",
      "Scala",
      "Elixir",
      "Haskell",
      "Lua"
    ]

    {:ok, mocked_live_rankings}
  end

  defp broadcast_ecosystem_rebalance(new_ranks) do
    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "world_tree:global",
      {:ecosystem_rebalanced, %{top_languages: new_ranks, timestamp: DateTime.utc_now()}}
    )
  end
end
