defmodule CodeMantra.Inventory.InventoryItem do
  @moduledoc """
  Tracks items held in a player's inventory or active equipment slots.
  """
  use Ash.Resource,
      domain: CodeMantra.Inventory,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "inventory_items"
    repo CodeMantra.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :grant_item do
      primary? true
      accept [:user_id, :item_definition_id, :quantity]
    end

    update :adjust_stack do
      argument :delta, :integer, allow_nil?: false
      change atomic_update(:quantity, expr(quantity + delta))
    end

    update :equip do
      change set_attribute(:equipped, true)
    end

    update :unequip do
      change set_attribute(:equipped, false)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :user_id, :uuid, allow_nil?: false
    attribute :quantity, :integer, default: 1
    attribute :equipped, :boolean, default: false
    attribute :durability, :integer, default: 100

    timestamps()
  end

  relationships do
    belongs_to :item_definition, CodeMantra.Inventory.ItemDefinition do
      attribute_writable? true
      allow_nil? false
    end
  end
end