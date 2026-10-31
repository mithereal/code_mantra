defmodule CodeMantra.Domain.SharedRank do
  @moduledoc """
  Ash Resource managing active competitive rankings, score aggregations,
  and real-time contestations across players and guilds.
  """
  use Ash.Resource,
      domain: CodeMantra.Gamification,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "shared_ranks"
    repo CodeMantra.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :entity_id, :string do
      allow_nil? false
      public? true
    end

    attribute :entity_type, :atom do
      allow_nil? false
      constraints one_of: [:player, :guild]
      public? true
    end

    attribute :score, :integer do
      allow_nil? false
      default 0
      public? true
    end

    attribute :rank_position, :integer do
      allow_nil? false
      default 999_999
      public? true
    end

    attribute :status, :atom do
      allow_nil? false
      default :active
      constraints one_of: [:active, :contested]
      public? true
    end

    attribute :realm_id, :string do
      allow_nil? false
      default "REALM-4aef81"
      public? true
    end

    timestamps()
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:entity_id, :entity_type, :score, :rank_position, :realm_id]
    end

    update :update do
      accept [:score, :rank_position, :status]
    end

    update :recalculate_score do
      description "Atomically updates score during telemetry events."
      argument :score_delta, :integer, allow_nil?: false

      change atomic_update(:score, expr(score + ^arg(:score_delta)))
    end

    read :leaderboard_for_realm do
      argument :realm_id, :string, allow_nil?: false
      filter expr(realm_id == ^arg(:realm_id))
    end
  end
end