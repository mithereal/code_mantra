defmodule CodeMantra.Workers.RankRebalancer do
  @moduledoc """
  Oban cron worker that runs periodically to evaluate tenant-wide EXP tallies,
  determine seasonal MVP placements, and mint LootLedger reward entries.
  """
  use Oban.Worker,
    queue: :default,
    max_attempts: 3,
    tags: ["ranks", "ledger", "rewards"]

  import Ash.Query

  alias CodeMantra.Identity.PlayerProfile
  alias CodeMantra.Ledger.LootLedger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"tenant_id" => tenant_id} = args}) do
    context_type = String.to_existing_atom(Map.get(args, "context", "corporate"))

    # Fetch top profiles in the tenant ordered by total EXP
    profiles =
      PlayerProfile
      |> for_tenant(tenant_id)
      |> sort(total_exp: :desc)
      |> limit(10)
      |> Ash.read!()

    case profiles do
      [] ->
        {:ok, :no_active_profiles}

      [mvp | runners_up] ->
        Ash.DataLayer.transaction(PlayerProfile, fn ->
          # 1. Distribute Legendary Tier Loot Box to the Tenant MVP
          award_loot_entry(
            tenant_id,
            mvp.id,
            :legendary_loot_box,
            Decimal.new("500.00"),
            8,
            context_type
          )

          # 2. Distribute Epic Chests to Top Runners-Up
          Enum.each(runners_up, fn profile ->
            award_loot_entry(
              tenant_id,
              profile.id,
              :epic_chest,
              Decimal.new("150.00"),
              4,
              context_type
            )
          end)
        end)

        {:ok, %{tenant_id: tenant_id, mvp_user_id: mvp.user_id, rewarded_count: length(profiles)}}
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: _global_args}) do
    # Global invocation: enqueue per-tenant jobs for isolated execution
    tenants = fetch_active_tenants()

    jobs =
      Enum.map(tenants, fn tenant_id ->
        new(%{"tenant_id" => tenant_id, "context" => "corporate"})
      end)

    Oban.insert_all(jobs)
    {:ok, %{enqueued_tenants: length(tenants)}}
  end

  # --- Internal Helpers ---

  defp award_loot_entry(tenant_id, profile_id, reward_type, bonus_amount, pto_hours, context) do
    LootLedger
    |> Ash.Changeset.for_create(
      :award_loot,
      %{
        tenant_id: tenant_id,
        player_profile_id: profile_id,
        reward_type: reward_type,
        bonus_amount: bonus_amount,
        pto_hours_granted: pto_hours,
        context: context,
        status: :pending
      },
      tenant: tenant_id
    )
    |> Ash.create!()
  end

  defp fetch_active_tenants do
    # Pull distinct active tenant identifiers from DB or configuration
    ["tenant_az_tucson", "tenant_oss_vanguard"]
  end
end
