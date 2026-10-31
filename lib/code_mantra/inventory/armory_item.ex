defmodule CodeMantra.Inventory.ArmoryItem do
  @moduledoc """
  Ash Resource defining weapons, staves, and procedural gear forged
  from repository cyclomatic complexity and compilation streaks.
  """
  use Ash.Resource,
      domain: CodeMantra.Inventory,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "armory_items"
    repo CodeMantra.Repo
  end

  multitenancy do
    strategy :attribute
    attribute :organization_id
  end

  actions do
    defaults [:read, :destroy]

    create :forge do
      primary? true
      accept [:name, :rarity, :damage_multiplier, :affinity, :durability, :user_id, :organization_id]
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

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :organization_id, :uuid, allow_nil?: false
    attribute :user_id, :uuid, allow_nil?: false

    attribute :rarity, :atom,
              default: :common,
              constraints: [one_of: [:common, :rare, :epic, :mythic, :ancient]]

    attribute :damage_multiplier, :float, default: 1.0

    attribute :affinity, :atom,
              default: :telemetry,
              constraints: [one_of: [:telemetry, :functional, :concurrency, :low_level, :architectural]]

    attribute :durability, :integer, default: 100
    attribute :equipped, :boolean, default: false

    timestamps()
  end

  identities do
    identity :unique_equipped_per_slot, [:user_id, :id]
  end
end