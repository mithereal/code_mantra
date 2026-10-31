defmodule CodeMantra.Gamification.MercenaryRewardEngine do
  @moduledoc """
  Handles cross-realm XP, Gold, and Mercenary Badge distribution when an
  external developer merges a PR or clears an issue in an open-source realm.
  """

  alias CodeMantra.Gamification
  alias CodeMantra.Domain.PlayerProfile

  # 35% XP bonus for assisting external open-source realms
  @mercenary_xp_multiplier 1.35
  @mercenary_gold_bonus 150

  @doc """
  Processes cross-realm bounty payouts for external contributors.
  """
  @spec payout_mercenary_bounty(String.t(), String.t(), map()) :: {:ok, map()} | {:error, term()}
  def payout_mercenary_bounty(visiting_user_id, target_realm_id, pr_stats) do
    with {:ok, profile} <- Ash.get(PlayerProfile, visiting_user_id, domain: Gamification),
         is_external <- profile.home_realm_id != target_realm_id do
      xp_earned =
        if is_external do
          round((pr_stats.base_xp + pr_stats.chambers_cleared * 100) * @mercenary_xp_multiplier)
        else
          pr_stats.base_xp
        end

      gold_earned =
        if is_external do
          pr_stats.base_gold + @mercenary_gold_bonus
        else
          pr_stats.base_gold
        end

      # Update player profile with cross-realm rewards
      updated_profile =
        profile
        |> Ash.Changeset.for_update(:reward_mercenary, %{
          xp: profile.xp + xp_earned,
          gold: profile.gold + gold_earned,
          mercenary_merits: profile.mercenary_merits + if(is_external, do: 1, else: 0)
        })
        |> Ash.update!(domain: Gamification)

      # Notify the visiting developer's home socket
      broadcast_mercenary_payout(
        visiting_user_id,
        target_realm_id,
        xp_earned,
        gold_earned,
        is_external
      )

      {:ok,
       %{
         user_id: visiting_user_id,
         xp_earned: xp_earned,
         gold_earned: gold_earned,
         mercenary_bonus_applied: is_external,
         total_merits: updated_profile.mercenary_merits
       }}
    end
  end

  defp broadcast_mercenary_payout(user_id, target_realm_id, xp, gold, is_external) do
    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "player:#{user_id}",
      {:mercenary_bounty_claimed,
       %{
         realm_id: target_realm_id,
         xp: xp,
         gold: gold,
         is_external: is_external
       }}
    )

    if is_external do
      # Public announcement on the open-source realm channel
      Phoenix.PubSub.broadcast(
        CodeMantra.PubSub,
        "realm:#{target_realm_id}",
        {:mercenary_assisted,
         %{
           adventurer_id: user_id,
           xp_granted: xp
         }}
      )
    end
  end
end
