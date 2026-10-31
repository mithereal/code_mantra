defmodule CodeMantra.Inventory do
  @moduledoc """
  The Ash Domain managing player item inventories, loot stashes,
  and equipment loadouts in CodeMantra.
  """
  use Ash.Domain

  resources do
    resource CodeMantra.Inventory.ItemDefinition
    resource CodeMantra.Inventory.InventoryItem
  end
end