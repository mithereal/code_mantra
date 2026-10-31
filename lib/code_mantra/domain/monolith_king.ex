defmodule CodeMantra.Domain.MonolithKing do
  @moduledoc """
  Ash Resource representing The Monolith King (Sovereign of Technical Debt).
  Tracks global world boss health, phase states, and dethroning actions.
  """
  use Ash.Resource,
      domain: CodeMantra.Gamification,
      data_layer: AshPostgres.DataLayer

  postgres do
    table "monolith_kings"
    repo CodeMantra.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :realm_id, :string do
      allow_nil? false
      default "REALM-4aef81"
      public? true
    end

    attribute :max_hp, :integer do
      allow_nil? false
      default 250_000
      public? true
    end

    attribute :current_hp, :integer do
      allow_nil? false
      public? true
    end

    attribute :phase, :atom do
      allow_nil? false
      default :syntactical_corruption
      constraints one_of: [:syntactical_corruption, :null_dereference, :infinite_recursion, :shattered]
      public? true
    end

    attribute :status, :atom do
      allow_nil? false
      default :active
      constraints one_of: [:active, :slain]
      public? true
    end

    timestamps()
  end

  actions do
    defaults [:read, :destroy]

    create :awaken do
      accept [:realm_id, :max_hp]
      change set_attribute(:current_hp, ref(:max_hp))
      change set_attribute(:status, :active)
      change set_attribute(:phase, :syntactical_corruption)
    end

    update :strike do
      accept []
      argument :damage, :integer, allow_nil?: false

      change fn changeset, _context ->
        current = Ash.Changeset.get_attribute(changeset, :current_hp) || 0
        damage = Ash.Changeset.get_argument(changeset, :damage)
        new_hp = max(0, current - damage)

        status = if new_hp == 0, do: :slain, else: :active
        phase = if new_hp <= 125_000 and status == :active, do: :null_dereference, else: Ash.Changeset.get_attribute(changeset, :phase)

        changeset
        |> Ash.Changeset.force_change_attribute(:current_hp, new_hp)
        |> Ash.Changeset.force_change_attribute(:status, status)
        |> Ash.Changeset.force_change_attribute(:phase, phase)
      end
    end

    update :dethrone do
      accept []
      change set_attribute(:current_hp, 0)
      change set_attribute(:status, :slain)
      change set_attribute(:phase, :shattered)
    end
  end
end