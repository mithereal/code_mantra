defmodule CodeMantra.Domain.PlayerProfile do
  @moduledoc """
  Ash Resource defining developer player profiles, class paradigms,
  cumulative XP, gold shards, and Yggdrasil world tree altitude progression.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("player_profiles")
    repo(CodeMantra.Repo)
  end

  actions do
    defaults([:read, :destroy])

    create :register do
      accept([:username, :github_handle, :class_paradigm])
    end

    update :award_telemetry_loot do
      argument(:xp_delta, :integer, allow_nil?: false)
      argument(:gold_delta, :integer, allow_nil?: false)

      change(atomic_update(:cumulative_xp, expr(cumulative_xp + ^arg(:xp_delta))))
      change(atomic_update(:gold_shards, expr(gold_shards + ^arg(:gold_delta))))
    end

    update :advance_altitude do
      change(atomic_update(:yggdrasil_altitude, expr(yggdrasil_altitude + 1)))
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :username, :string do
      allow_nil?(false)
    end

    attribute(:github_handle, :string)

    attribute :class_paradigm, :atom do
      constraints(one_of: [:functional, :low_level, :dynamic, :general])
      default(:functional)
      allow_nil?(false)
    end

    attribute :cumulative_xp, :integer do
      default(0)
      allow_nil?(false)
    end

    attribute :gold_shards, :integer do
      default(0)
      allow_nil?(false)
    end

    attribute :yggdrasil_altitude, :integer do
      default(1)
      allow_nil?(false)
    end

    timestamps()
  end

  relationships do
    has_many :armory_items, CodeMantra.Domain.ArmoryItem
  end

  identities do
    identity(:unique_username, [:username])
  end
end
