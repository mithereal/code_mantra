defmodule CodeMantra.Domain.RaidEncounter do
  @moduledoc """
  Ash Resource tracking active, defeated, and fled raid encounters spawned by
  Actor 5 (DungeonOrchestrator) as a result of cyclomatic complexity anomalies and merge conflicts.
  """
  use Ash.Resource,
      domain: CodeMantra.Gamification,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "raid_encounters"
    repo CodeMantra.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      allow_nil? false
      public? true
    end

    attribute :boss_name, :string do
      allow_nil? false
      public? true
    end

    attribute :boss_id, :string do
      public? true
    end

    attribute :origin_file, :string do
      allow_nil? false
      public? true
    end

    attribute :threat_level, :integer do
      allow_nil? false
      default 1
      public? true
    end

    attribute :difficulty, :atom do
      allow_nil? false
      default :heroic
      constraints one_of: [:normal, :heroic, :mythic, :legendary]
      public? true
    end

    attribute :status, :atom do
      allow_nil? false
      default :active
      constraints one_of: [:queued, :active, :victorious, :defeated, :fled, :wipe]
      public? true
    end

    attribute :participant_ids, {:array, :string} do
      allow_nil? false
      default []
      public? true
    end

    timestamps()
  end

  actions do
    defaults [:read, :destroy]

    create :spawn do
      accept [:title, :boss_name, :boss_id, :origin_file, :threat_level, :difficulty, :participant_ids]
      change set_attribute(:status, :active)
    end

    update :conquer do
      accept []
      change set_attribute(:status, :defeated)
    end

    update :fail_encounter do
      accept []
      change set_attribute(:status, :fled)
    end

    update :complete_raid do
      description "Updates encounter completion status with custom outcome mapping."
      argument :final_status, :atom, allow_nil?: false, constraints: [one_of: [:victorious, :defeated, :fled, :wipe]]

      change fn changeset, _context ->
        status = Ash.Changeset.get_argument(changeset, :final_status)
        Ash.Changeset.change_attribute(changeset, :status, status)
      end
    end
  end
end