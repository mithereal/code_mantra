defmodule CodeMantra.Domain.SkillNode do
  @moduledoc """
  Ash Resource defining unlockable developer skill tree perks (e.g., XP multipliers,
  crit damage bonuses, vault tax reductions) purchased with accumulated gold shards or skill points.
  """
  use Ash.Resource,
      domain: CodeMantra.Gamification,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "skill_nodes"
    repo CodeMantra.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :description, :string do
      public? true
    end

    attribute :category, :atom do
      allow_nil? false
      default :functional_core
      constraints one_of: [:functional_core, :otp_concurrency, :macro_meta, :ash_resource]
      public? true
    end

    attribute :perk_type, :atom do
      allow_nil? false
      default :xp_boost
      constraints one_of: [:xp_boost, :crit_multiplier, :vault_tax_reduction, :memory_shield]
      public? true
    end

    attribute :tier, :integer do
      allow_nil? false
      default 1
      public? true
    end

    attribute :cost_sp, :integer do
      allow_nil? false
      default 1
      public? true
    end

    attribute :unlocked, :boolean do
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

    create :unlock do
      accept [:name, :description, :category, :perk_type, :tier, :cost_sp, :player_id]
      change set_attribute(:unlocked, true)
    end

    create :create do
      accept [:name, :description, :category, :perk_type, :tier, :cost_sp, :unlocked, :player_id]
    end

    update :update do
      accept [:name, :description, :category, :perk_type, :tier, :cost_sp, :unlocked]
    end

    update :unlock_node do
      description "Unlocks the skill node, marking it as active and granting passive paradigm bonuses."
      change set_attribute(:unlocked, true)
    end
  end
end