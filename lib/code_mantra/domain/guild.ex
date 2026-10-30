defmodule CodeMantra.Domain.Guild do
  @moduledoc """
  Ash Resource defining Guild Citadels, collective vault gold, and team perks.
  """
  use Ash.Resource,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "guilds"
    repo CodeMantra.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :found do
      accept [:name, :tag]
    end

    update :deposit_vault_gold do
      argument :amount, :integer, allow_nil?: false
      change atomic_update(:vault_gold, expr(vault_gold + ^arg(:amount)))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
    end

    attribute :tag, :string do
      allow_nil? false
      constraints [min_length: 2, max_length: 4]
    end

    attribute :level, :integer do
      default 1
    end

    attribute :total_xp, :integer do
      default 0
    end

    attribute :vault_gold, :integer do
      default 0
    end

    timestamps()
  end

  identities do
    identity :unique_tag, [:tag]
  end
end