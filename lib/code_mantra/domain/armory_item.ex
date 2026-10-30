defmodule CodeMantra.Domain.ArmoryItem do
  @moduledoc """
  Ash Resource defining weapons, staves, and gear forged procedurally
  from language cyclomatic complexity and code compilation streaks.
  """
  use Ash.Resource,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "armory_items"
    repo CodeMantra.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :forge do
      accept [:name, :rarity, :damage_multiplier, :affinity, :player_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :rarity, :atom do
      constraints [one_of: [:common, :rare, :epic, :mythic]]
      default :common
      allow_nil? false
    end

    attribute :damage_multiplier, :float do
      default 1.0
      allow_nil? false
    end

    attribute :affinity, :atom do
      default :telemetry
      allow_nil? false
    end

    timestamps()
  end

  relationships do
    belongs_to :player, CodeMantra.Domain.PlayerProfile do
      attribute_writable? true
      allow_nil? false
    end
  end
end