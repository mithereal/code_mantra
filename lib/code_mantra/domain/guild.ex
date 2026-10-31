defmodule CodeMantra.Domain.Guild do
  @moduledoc """
  Ash Resource defining Guild Citadels, collective vault gold, team perks,
  and shared raid progress within the CodeMantra domain.
  """
  use Ash.Resource,
      domain: CodeMantra.Gamification,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "guilds"
    repo CodeMantra.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :tag, :string do
      allow_nil? false
      constraints [min_length: 2, max_length: 4]
      public? true
    end

    attribute :level, :integer do
      allow_nil? false
      default 1
      public? true
    end

    attribute :total_xp, :integer do
      allow_nil? false
      default 0
      public? true
    end

    attribute :vault_gold, :integer do
      allow_nil? false
      default 0
      public? true
    end

    attribute :leader_id, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  identities do
    identity :unique_tag, [:tag]
  end

  relationships do
    has_many :members, CodeMantra.Domain.PlayerProfile do
      destination_attribute :guild_id
    end
  end

  actions do
    defaults [:read, :destroy]

    create :found do
      accept [:name, :tag, :leader_id]
    end

    create :create do
      accept [:name, :tag, :leader_id, :level, :total_xp, :vault_gold]
    end

    update :update do
      accept [:name, :tag, :level, :total_xp, :vault_gold, :leader_id]
    end

    update :deposit_vault_gold do
      description "Atomically deposits gold shards into the guild vault from completed raids."
      argument :amount, :integer, allow_nil?: false
      change atomic_update(:vault_gold, expr(vault_gold + ^arg(:amount)))
    end

    update :level_up do
      description "Increments guild level upon reaching collective XP thresholds."
      change atomic_update(:level, expr(level + 1))
    end
  end
end