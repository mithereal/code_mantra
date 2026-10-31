defmodule CodeMantra.Realms.WorldTree do
  @moduledoc """
  Tracks global World Tree canopy height, inheriting tenant isolation from its repository.
  """
  use Ash.Resource,
      domain: CodeMantra.Realms,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "world_trees"
    repo CodeMantra.Repo
  end

  multitenancy do
    strategy :attribute
    attribute :organization_id
  end

  actions do
    defaults [:read]

    create :initialize do
      primary? true
      accept [:repository_id, :organization_id]
    end

    update :grow_canopy do
      argument :xp_added, :integer, allow_nil?: false

      change atomic_update(:total_ascension_xp, expr(total_ascension_xp + xp_added))
      change atomic_update(:canopy_height, expr(canopy_height + div(xp_added, 100)))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :organization_id, :uuid, allow_nil?: false
    attribute :canopy_height, :integer, default: 10
    attribute :total_ascension_xp, :integer, default: 0
    attribute :active_buffs, {:array, :map}, default: []

    timestamps()
  end

  relationships do
    belongs_to :repository, CodeMantra.Realms.Repository
  end
end