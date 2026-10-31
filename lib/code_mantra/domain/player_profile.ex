defmodule CodeMantra.Domain.PlayerProfile do
  @moduledoc """
  Ash Resource defining developer player profiles, class paradigms,
  cumulative XP, gold shards, Yggdrasil world tree altitude progression,
  and guild associations within the CodeMantra domain.
  """
  use Ash.Resource,
      domain: CodeMantra.Gamification,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "player_profiles"
    repo CodeMantra.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :username, :string do
      allow_nil? false
      public? true
    end

    attribute :github_handle, :string do
      public? true
    end

    attribute :class_paradigm, :atom do
      allow_nil? false
      default :functional
      constraints one_of: [:functional, :low_level, :dynamic, :general]
      public? true
    end

    attribute :level, :integer do
      allow_nil? false
      default 1
      public? true
    end

    attribute :cumulative_xp, :integer do
      allow_nil? false
      default 0
      public? true
    end

    attribute :gold_shards, :integer do
      allow_nil? false
      default 0
      public? true
    end

    attribute :yggdrasil_altitude, :integer do
      allow_nil? false
      default 1
      public? true
    end

    attribute :guild_id, :uuid do
      public? true
    end

    timestamps()
  end

  identities do
    identity :unique_username, [:username]
  end

  relationships do
    belongs_to :guild, CodeMantra.Domain.Guild do
      source_attribute :guild_id
    end

    has_many :armory_items, CodeMantra.Domain.ArmoryItem do
      destination_attribute :owner_id
    end
  end

  actions do
    defaults [:read, :destroy]

    create :register do
      accept [:username, :github_handle, :class_paradigm, :guild_id]
    end

    create :create do
      accept [:username, :github_handle, :class_paradigm, :level, :cumulative_xp, :gold_shards, :yggdrasil_altitude, :guild_id]
    end

    update :update do
      accept [:username, :github_handle, :class_paradigm, :level, :cumulative_xp, :gold_shards, :yggdrasil_altitude, :guild_id]
    end

    update :award_telemetry_loot do
      description "Atomically awards XP and Gold shards accumulated from ambient code activity."
      argument :xp_delta, :integer, allow_nil?: false
      argument :gold_delta, :integer, allow_nil?: false

      change atomic_update(:cumulative_xp, expr(cumulative_xp + ^arg(:xp_delta)))
      change atomic_update(:gold_shards, expr(gold_shards + ^arg(:gold_delta)))
    end

    update :advance_altitude do
      description "Increments player Yggdrasil world tree elevation."
      change atomic_update(:yggdrasil_altitude, expr(yggdrasil_altitude + 1))
    end
  end
end