defmodule CodeMantra.Realms.Repository do
  @moduledoc """
  Represents a monitored Git repository realm with enterprise tenant isolation.
  """
  use Ash.Resource,
      domain: CodeMantra.Realms,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "repositories"
    repo CodeMantra.Repo
  end

  multitenancy do
    strategy :attribute
    attribute :organization_id
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:name, :org, :default_branch, :language, :organization_id]

      change set_attribute(:realm_id, expr(org <> "/" <> name))
    end

    update :report_debt do
      argument :debt_delta, :integer, allow_nil?: false
      change atomic_update(:technical_debt_score, expr(technical_debt_score + debt_delta))
    end

    update :reset_debt do
      change set_attribute(:technical_debt_score, 0)
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if(attribute(:organization_id, actor(:organization_id)))
    end

    policy action_type(:update) do
      authorize_if(attribute(:organization_id, actor(:organization_id)))
      authorize_if(actor(:role) == :org_admin)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :realm_id, :string, allow_nil?: false
    attribute :name, :string, allow_nil?: false
    attribute :org, :string, allow_nil?: false
    attribute :organization_id, :uuid, allow_nil?: false
    attribute :default_branch, :string, default: "main"
    attribute :language, :string, default: "Elixir"
    attribute :technical_debt_score, :integer, default: 0

    timestamps()
  end

  relationships do
    has_many :branches, CodeMantra.Realms.Branch, foreign_key: :repository_id
    has_one :world_tree, CodeMantra.Realms.WorldTree, foreign_key: :repository_id
  end

  identities do
    identity :unique_realm_per_org, [:organization_id, :realm_id]
  end
end