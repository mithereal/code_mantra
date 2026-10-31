defmodule CodeMantra.Realms.CorporateRealm do
  @moduledoc """
  Ash resource representing an enterprise corporate repository.
  Enforces tenant isolation and strict team-only access policies.
  """
  use Ash.Resource,
    domain: CodeMantra.Realms,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("corporate_realms")
    repo(CodeMantra.Repo)
  end

  multitenancy do
    strategy(:attribute)
    attribute(:organization_id)
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      primary?(true)
      accept([:realm_id, :repository_name, :organization_id])
    end

    update :update do
      accept([:canopy_height, :technical_debt_score])
    end
  end

  policies do
    # Only allow actors belonging to the exact organization tenant
    policy action_type(:read) do
      authorize_if(attribute(:organization_id, actor(:organization_id)))
    end

    policy action_type(:update) do
      authorize_if(attribute(:organization_id, actor(:organization_id)))
      authorize_if(actor(:role) == :org_admin)
    end
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:realm_id, :string, allow_nil?: false)
    attribute(:repository_name, :string, allow_nil?: false)
    attribute(:organization_id, :uuid, allow_nil?: false)
    attribute(:canopy_height, :integer, default: 0)
    attribute(:technical_debt_score, :integer, default: 0)

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end
end
