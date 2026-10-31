defmodule CodeMantra.Domain.SharedRank do
  @moduledoc """
  Ash Resource storing procedurally generated ranks and royal titles
  so they can be archived and inherited by other developers in the guild/repository.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("shared_ranks")
    repo(CodeMantra.Repo)
  end

  actions do
    defaults([:read, :destroy])

    create :archive do
      accept([:title, :rank_name, :tier_badge, :paradigm, :creator_id, :realm_id])
    end

    read :for_realm do
      argument(:realm_id, :string, allow_nil?: false)
      filter(expr(realm_id == ^arg(:realm_id)))
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :title, :string do
      allow_nil?(false)
    end

    attribute :rank_name, :string do
      allow_nil?(false)
    end

    attribute :tier_badge, :string do
      allow_nil?(false)
    end

    attribute :paradigm, :atom do
      allow_nil?(false)
    end

    attribute :creator_id, :string do
      allow_nil?(false)
    end

    attribute :realm_id, :string do
      default("REALM-4aef81")
      allow_nil?(false)
    end

    timestamps()
  end
end
