defmodule CodeMantra.Dungeon.PRMergeHandler do
  @moduledoc """
  Processes Pull Request merge events. Calculates ascension loot, distributes XP/Gold
  to realm developers, updates World Tree height, and broadcasts victory notifications.
  """
  require Logger

  alias CodeMantra.Dungeon.BranchDungeonActor
  alias CodeMantra.Gamification
  alias CodeMantra.Domain.PlayerProfile

  @doc """
  Executes the PR merge ascension pipeline.

  ## Parameters:
    - `realm_id`: The project repository identifier (e.g., "my_org/my_repo")
    - `source_branch`: The feature branch being merged (e.g., "feature/auth")
    - `target_branch`: The destination branch (e.g., "main" or "staging")
    - `pr_meta`: %{pr_id: integer(), author_id: String.to_atom() | String.t(), contributors: list(), commits_count: integer()}
  """
  @spec process_merge(String.t(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, term()}
  def process_merge(realm_id, source_branch, target_branch, pr_meta) do
    with {:ok, dungeon_state} <- fetch_branch_dungeon(realm_id, source_branch),
         loot_payload <- calculate_ascension_loot(dungeon_state, pr_meta, target_branch),
         {:ok, _} <- distribute_loot(realm_id, loot_payload),
         {:ok, new_height} <-
           advance_world_tree(realm_id, target_branch, loot_payload.ascension_xp) do

      # Broadcast global ascension event across the PubSub topic
      broadcast_ascension_victory(realm_id, %{
        source_branch: source_branch,
        target_branch: target_branch,
        pr_id: pr_meta.pr_id,
        author_id: pr_meta.author_id,
        new_world_height: new_height,
        loot: loot_payload
      })

      # Clean up or archive the feature branch dungeon actor
      archive_branch_dungeon(realm_id, source_branch)

      Logger.info("🌟 [PR_MERGE] Branch '#{source_branch}' successfully merged into '#{target_branch}' for realm #{realm_id}!")

      {:ok,
        %{
          status: :ascended,
          new_world_height: new_height,
          distributed_loot: loot_payload
        }}
    end
  end

  # --- Internal Steps ---

  defp fetch_branch_dungeon(realm_id, branch_name) do
    case Registry.lookup(CodeMantra.DungeonRegistry, "#{realm_id}:#{branch_name}") do
      [{pid, _}] when is_pid(pid) ->
        state = GenServer.call(pid, :get_state)
        {:ok, state}

      [] ->
        # Fallback if the actor was hibernated or uninitialized
        {:ok, %{dungeon_rooms: %{}, world_tree_level: 10}}
    end
  end

  defp calculate_ascension_loot(dungeon_state, pr_meta, target_branch) do
    cleared_chambers =
      dungeon_state.dungeon_rooms
      |> Map.values()
      |> Enum.count(& &1.cleared)

    base_xp = 500
    issue_bonus_xp = cleared_chambers * 250
    commit_bonus_xp = min(pr_meta.commits_count * 50, 1000)

    target_multiplier =
      case target_branch do
        "main" -> 2.0
        "master" -> 2.0
        "staging" -> 1.5
        _ -> 1.0
      end

    total_xp = round((base_xp + issue_bonus_xp + commit_bonus_xp) * target_multiplier)
    total_gold = round(total_xp * 0.4)

    contributors = Enum.uniq([pr_meta.author_id | Map.get(pr_meta, :contributors, [])])

    %{
      total_xp: total_xp,
      total_gold: total_gold,
      # Points fed into the World Tree Canopy
      ascension_xp: round(total_xp * 0.5),
      contributors: contributors,
      chambers_cleared: cleared_chambers
    }
  end

  defp distribute_loot(_realm_id, %{contributors: contributors, total_xp: xp, total_gold: gold}) do
    contributor_count = max(1, Enum.count(contributors))
    per_contributor_xp = max(1, div(xp, contributor_count))
    per_contributor_gold = max(1, div(gold, contributor_count))

    Enum.each(contributors, fn user_id ->
      # Grant XP and Gold Shards via Ash changesets or domain actions
      case Ash.get(PlayerProfile, user_id, domain: Gamification) do
        {:ok, profile} when not is_nil(profile) ->
          profile
          |> Ash.Changeset.for_update(:reward, %{
            xp: profile.xp + per_contributor_xp,
            gold: profile.gold + per_contributor_gold
          })
          |> Ash.update!(domain: Gamification)

          # Notify individual player socket
          Phoenix.PubSub.broadcast(
            CodeMantra.PubSub,
            "player:#{user_id}",
            {:xp_gained, %{xp: per_contributor_xp, gold: per_contributor_gold, wpm: 0}}
          )

        _ ->
          :ok
      end
    end)

    {:ok, :distributed}
  end

  defp advance_world_tree(realm_id, _target_branch, ascension_xp) do
    # Fetch or update the Realm's global World Tree state
    # Ascension XP pushes the canopy height up
    height_delta = div(ascension_xp, 100)

    # Broadcast tree progression
    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "world_tree:#{realm_id}",
      {:canopy_height_increased, %{height_delta: height_delta}}
    )

    {:ok, height_delta}
  end

  defp broadcast_ascension_victory(realm_id, payload) do
    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "realm:#{realm_id}",
      {:branch_ascended, payload}
    )
  end

  defp archive_branch_dungeon(realm_id, branch_name) do
    case Registry.lookup(CodeMantra.DungeonRegistry, "#{realm_id}:#{branch_name}") do
      [{pid, _}] -> GenServer.stop(pid, :normal)
      [] -> :ok
    end
  end
end