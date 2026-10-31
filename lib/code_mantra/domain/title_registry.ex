defmodule CodeMantra.Domain.TitleRegistry do
  @moduledoc """
  Ash Resource storing procedurally generated ranks, royal titles, and paradigm badges
  archived for historical record and lineage tracking within a realm.
  """
  use Ash.Resource,
      domain: CodeMantra.Gamification,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "title_registries"
    repo CodeMantra.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      allow_nil? false
      public? true
    end

    attribute :rank_name, :string do
      allow_nil? false
      public? true
    end

    attribute :tier_badge, :string do
      allow_nil? false
      public? true
    end

    attribute :paradigm, :atom do
      allow_nil? false
      constraints one_of: [:functional, :low_level, :dynamic, :general]
      public? true
    end

    attribute :creator_id, :string do
      allow_nil? false
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

    create :archive do
      accept [:title, :rank_name, :tier_badge, :paradigm, :creator_id, :realm_id]
    end

    read :for_realm do
      argument :realm_id, :string, allow_nil?: false
      filter expr(realm_id == ^arg(:realm_id))
    end
  end
end