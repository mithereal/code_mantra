defmodule CodeMantra.Domain.RaidEncounter do
  @moduledoc """
  Ash Resource tracking active and defeated raid bosses spawned by Actor 5 (DungeonOrchestrator)
  as a result of cyclomatic complexity anomalies and merge conflicts.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("raid_encounters")
    repo(CodeMantra.Repo)
  end

  actions do
    defaults([:read, :destroy])

    create :spawn do
      accept([:boss_name, :threat_level, :origin_file])
    end

    update :conquer do
      change(set_attribute(:status, :defeated))
    end

    update :fail_encounter do
      change(set_attribute(:status, :fled))
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :boss_name, :string do
      allow_nil?(false)
    end

    attribute :threat_level, :integer do
      default(1)
      allow_nil?(false)
    end

    attribute :origin_file, :string do
      allow_nil?(false)
    end

    attribute :status, :atom do
      constraints(one_of: [:active, :defeated, :fled])
      default(:active)
      allow_nil?(false)
    end

    timestamps()
  end
end
