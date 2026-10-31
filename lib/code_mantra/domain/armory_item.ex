defmodule CodeMantra.Domain.ArmoryItem do
  @moduledoc """
  Ash Resource defining weapons, staves, and gear forged procedurally
  from language cyclomatic complexity and compilation streaks.
  """
  use Ash.Resource,
      domain: CodeMantra.Gamification,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "armory_items"
    repo CodeMantra.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :rarity, :atom do
      allow_nil? false
      default :common
      constraints one_of: [:common, :rare, :epic, :mythic]
      public? true
    end

    attribute :damage_multiplier, :float do
      allow_nil? false
      default 1.0
      public? true
    end

    attribute :affinity, :atom do
      allow_nil? false
      default :telemetry
      constraints one_of: [:telemetry, :functional, :concurrency, :low_level, :architectural]
      public? true
    end

    attribute :durability, :integer do
      allow_nil? false
      default 100
      public? true
    end

    attribute :equipped, :boolean do
      allow_nil? false
      default false
      public? true
    end

    attribute :player_id, :uuid do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :player, CodeMantra.Domain.PlayerProfile do
      attribute_writable? true
      allow_nil? false
    end
  end

  actions do
    defaults [:read, :destroy]

    create :forge do
      accept [:name, :rarity, :damage_multiplier, :affinity, :durability, :player_id]
    end

    create :create do
      accept [:name, :rarity, :damage_multiplier, :affinity, :durability, :equipped, :player_id]
    end

    update :update do
      accept [:name, :rarity, :damage_multiplier, :affinity, :durability, :equipped]
    end

    update :equip do
      description "Equips the gear piece to the owner's active loadout."
      change set_attribute(:equipped, true)
    end

    update :unequip do
      description "Unequips the gear piece, returning it to inventory."
      change set_attribute(:equipped, false)
    end

    update :repair do
      description "Restores item durability back to max capacity (100)."
      change set_attribute(:durability, 100)
    end
  end
end