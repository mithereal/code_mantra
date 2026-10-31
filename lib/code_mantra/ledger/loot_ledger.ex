defmodule CodeMantra.Ledger.LootLedger do
  @moduledoc """
  Ash Resource operating as an immutable audit log for corporate payroll
  disbursements, PTO bonuses, and open-source bounty distributions.
  """
  use Ash.Resource,
      domain: CodeMantra.Ledger,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "loot_ledgers"
    repo CodeMantra.Repo
  end

  multitenancy do
    strategy :attribute
    attribute :organization_id
  end

  actions do
    defaults [:read]

    create :award_loot do
      primary? true
      accept [
        :organization_id,
        :player_profile_id,
        :reward_type,
        :bonus_amount,
        :pto_hours_granted,
        :context,
        :status
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :organization_id, :uuid do
      allow_nil? false
      public? true
    end

    attribute :reward_type, :atom do
      constraints one_of: [:legendary_loot_box, :epic_chest, :standard_pouch, :oss_bounty]
      allow_nil? false
      public? true
    end

    attribute :bonus_amount, :decimal do
      default 0.0
      public? true
    end

    attribute :pto_hours_granted, :integer do
      default 0
      public? true
    end

    attribute :context, :atom do
      constraints one_of: [:corporate, :open_source]
      default :corporate
      public? true
    end

    attribute :status, :atom do
      constraints one_of: [:pending, :dispatched, :failed]
      default :pending
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :player_profile, CodeMantra.Domain.PlayerProfile do
      attribute_writable? true
      allow_nil? false
    end
  end
end