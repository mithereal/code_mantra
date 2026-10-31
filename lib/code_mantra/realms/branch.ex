defmodule CodeMantra.Realms.Branch do
  @moduledoc """
  Represents a feature branch within a realm repository.
  Acts as the persistent backing store for dynamic BranchDungeonActors.
  """
  use Ash.Resource,
      domain: CodeMantra.Realms,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "realm_branches"
    repo CodeMantra.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :register do
      primary? true
      accept [:name, :repository_id, :author_id]
      change set_attribute(:status, :active)
    end

    update :ascend do
      accept [:chambers_cleared, :total_xp_awarded]
      change set_attribute(:status, :ascended)
      change set_attribute(:ascended_at, &DateTime.utc_now/0)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :status, :atom, default: :active, constraints: [one_of: [:active, :ascended, :archived]]
    attribute :chambers_cleared, :integer, default: 0
    attribute :total_xp_awarded, :integer, default: 0
    attribute :author_id, :uuid, allow_nil?: false
    attribute :ascended_at, :utc_datetime_usec

    timestamps()
  end

  relationships do
    belongs_to :repository, CodeMantra.Realms.Repository
  end

  identities do
    identity :unique_branch_per_repo, [:repository_id, :name]
  end
end