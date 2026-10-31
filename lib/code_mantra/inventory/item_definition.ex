defmodule CodeMantra.Inventory.ItemDefinition do
  @moduledoc """
  Catalog of all standard and rare items, equipment, and relics in CodeMantra.
  """
  use Ash.Resource,
      domain: CodeMantra.Inventory,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "item_definitions"
    repo CodeMantra.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:name, :category, :rarity, :effect_payload, :description]
    end

    update :update do
      accept [:name, :effect_payload, :description]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :category, :atom, default: :consumable, constraints: [one_of: [:consumable, :equipment, :relic, :crafting_material]]
    attribute :rarity, :atom, default: :common, constraints: [one_of: [:common, :uncommon, :rare, :legendary, :ancient]]
    attribute :effect_payload, :map, default: %{}
    attribute :description, :string

    timestamps()
  end

  relationships do
    has_many :inventory_items, CodeMantra.Inventory.InventoryItem, foreign_key: :item_definition_id
  end

  identities do
    identity :unique_item_name, [:name]
  end
end