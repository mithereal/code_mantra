defmodule CodeMantra.Rewards.CorporateLootBox do
  @moduledoc """
  Ash Resource representing a manager-awarded Corporate Loot Box tied
  to real-world enterprise rewards (Gift Cards, Pay Raises, PTO Days, Tech Stipends).
  """
  use Ash.Resource,
    domain: CodeMantra.Rewards,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("corporate_loot_boxes")
    repo(CodeMantra.Repo)
  end

  multitenancy do
    strategy(:attribute)
    attribute(:organization_id)
  end

  actions do
    defaults([:read])

    # Action 1: Manager Grants Loot Box
    create :grant do
      accept([:recipient_id, :granted_by_id, :tier, :reason])

      change(set_attribute(:status, :unopened))
    end

    # Action 2: Developer Opens Loot Box
    update :open do
      accept([])

      # Validates that the loot box hasn't already been opened
      validate(attribute_equals(:status, :unopened))

      change(set_attribute(:status, :opened))
      change(set_attribute(:opened_at, &DateTime.utc_now/0))
      change(:roll_real_world_reward)
    end

    # Action 3: HR/Finance Fulfills Real-World Payout (e.g., Pay Raise Processed)
    update :fulfill_payout do
      accept([:payout_notes, :processed_by_hr_id])

      validate(attribute_equals(:status, :opened))
      change(set_attribute(:status, :fulfilled))
      change(set_attribute(:fulfilled_at, &DateTime.utc_now/0))
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:organization_id, :uuid, allow_nil?: false)
    attribute(:recipient_id, :uuid, allow_nil?: false)
    attribute(:granted_by_id, :uuid, allow_nil?: false)
    attribute(:processed_by_hr_id, :uuid)

    attribute(:tier, :atom,
      default: :rare_crate,
      constraints: [one_of: [:rare_crate, :epic_crate, :legendary_vault]]
    )

    attribute(:reason, :string, allow_nil?: false)

    attribute(:status, :atom,
      default: :unopened,
      constraints: [one_of: [:unopened, :opened, :fulfilled]]
    )

    # Real-World Reward Outcome
    attribute(:reward_type, :atom,
      constraints: [one_of: [:pay_raise_percent, :gift_card_usd, :pto_hours, :tech_stipend_usd]]
    )

    # e.g., 5 ($500 stipend / 5% raise), 50 ($50 gift card), 8 (8 hrs PTO)
    attribute(:reward_value, :integer)
    attribute(:payout_notes, :string)

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
    attribute(:opened_at, :utc_datetime_usec)
    attribute(:fulfilled_at, :utc_datetime_usec)
  end

  # Custom Change Callback: Loot Table Odds based on Box Tier
  defmodule Changes.RollRealWorldReward do
    use Ash.Resource.Change

    @impl true
    def change(changeset, _opts, _context) do
      tier = Ash.Changeset.get_attribute(changeset, :tier)
      {reward_type, value} = roll_loot_table(tier)

      changeset
      |> Ash.Changeset.force_change_attribute(:reward_type, reward_type)
      |> Ash.Changeset.force_change_attribute(:reward_value, value)
    end

    # Loot Table Logic
    defp roll_loot_table(:legendary_vault) do
      case :rand.uniform(100) do
        # 10% chance: 5% Permanent Pay Raise
        n when n <= 10 -> {:pay_raise_percent, 5}
        # 30% chance: $1,000 Hardware/Gear Stipend
        n when n <= 40 -> {:tech_stipend_usd, 1000}
        # 30% chance: 2 Days Paid PTO
        n when n <= 70 -> {:pto_hours, 16}
        # 30% chance: $250 Amazon/Visa Gift Card
        _ -> {:gift_card_usd, 250}
      end
    end

    defp roll_loot_table(:epic_crate) do
      case :rand.uniform(100) do
        # 5% chance: 2% Pay Raise
        n when n <= 5 -> {:pay_raise_percent, 2}
        # 30% chance: $500 Tech Stipend
        n when n <= 35 -> {:tech_stipend_usd, 500}
        # 30% chance: 1 Day Paid PTO
        n when n <= 65 -> {:pto_hours, 8}
        # 35% chance: $100 Gift Card
        _ -> {:gift_card_usd, 100}
      end
    end

    defp roll_loot_table(_rare_crate) do
      case :rand.uniform(100) do
        # 40% chance: $50 Gift Card
        n when n <= 40 -> {:gift_card_usd, 50}
        # 40% chance: Half-day PTO (4 hrs)
        n when n <= 80 -> {:pto_hours, 4}
        # 20% chance: $150 Desk/Book Stipend
        _ -> {:tech_stipend_usd, 150}
      end
    end
  end
end
