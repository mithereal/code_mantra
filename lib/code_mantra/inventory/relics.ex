defmodule CodeMantra.Inventory.Relic do
  @moduledoc """
  Ash Resource representing ancient code relics awakened through rituals,
  providing passive stat boosts and paradigm synergies.
  """
  use Ash.Resource,
      domain: CodeMantra.Gamification,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "relics"
    repo CodeMantra.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :tier, :atom do
      allow_nil? false
      constraints one_of: [:dormant, :awakened, :mythic_monolith]
      default :dormant
      public? true
    end

    attribute :paradigm_affinity, :atom do
      allow_nil? false
      constraints one_of: [:functional, :low_level, :async_pipeline, :macro_meta]
      public? true
    end

    attribute :power_rating, :integer do
      allow_nil? false
      default 100
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

    create :awaken do
      accept [:name, :tier, :paradigm_affinity, :power_rating, :realm_id]
    end

    update :empower do
      accept [:power_rating, :tier]
    end

    read :for_realm do
      argument :realm_id, :string, allow_nil?: false
      filter expr(realm_id == ^arg(:realm_id))
    end
  end
end