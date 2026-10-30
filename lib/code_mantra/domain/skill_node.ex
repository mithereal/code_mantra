defmodule CodeMantra.Domain.SkillNode do
  @moduledoc """
  Ash Resource defining unlockable developer skill tree perks (e.g., XP multipliers,
  crit damage bonuses, vault tax reductions) purchased with accumulated gold shards.
  """
  use Ash.Resource,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "skill_nodes"
    repo CodeMantra.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :unlock do
      accept [:name, :tier, :perk_type, :player_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :tier, :integer do
      default 1
      allow_nil? false
    end

    attribute :perk_type, :atom do
      constraints [one_of: [:xp_boost, :crit_multiplier, :vault_tax_reduction, :memory_shield]]
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