defmodule CodeMantra.Identity.PlayerProfile do
  @moduledoc """
  Ash Resource representing a developer's persistent identity,
  total accumulated EXP, calculated level, and telemetry metrics.
  """
  use Ash.Resource,
    domain: CodeMantra.Identity,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("player_profiles")
    repo(CodeMantra.Repo)
  end

  multitenancy do
    strategy(:attribute)
    attribute(:tenant_id)
  end

  actions do
    defaults([:read, :destroy])

    create :register do
      primary?(true)
      accept([:user_id, :handle, :editor_archetype, :familiar_type, :tenant_id])
    end

    update :update_telemetry do
      accept([:main_language_rank, :flow_multiplier, :mvp_score, :familiar_level])
      change(increment(:total_commits_slain))
    end

    # Add inside the actions block of lib/code_mantra/identity/resources/player_profile.ex

    update :promote_rank do
      argument(:new_rank, :integer, allow_nil?: false)

      change(fn changeset, _context ->
        new_rank = Ash.Changeset.get_argument(changeset, :new_rank)
        total_exp = Ash.Changeset.get_attribute(changeset, :total_exp) || 0

        # Calculate rank qualification
        eval = CodeMantra.Identity.RankCalculator.evaluate_progression(total_exp, 0)

        if new_rank <= eval.earned_rank do
          Ash.Changeset.force_change_attribute(changeset, :main_language_rank, new_rank)
        else
          Ash.Changeset.add_error(
            changeset,
            Ash.Error.Changes.InvalidAttribute.exception(
              field: :main_language_rank,
              message: "The King denies your promotion! Insufficient EXP for Rank #{new_rank}."
            )
          )
        end
      end)
    end

    update :award_exp do
      argument(:exp_gained, :integer, allow_nil?: false)

      change(fn changeset, _context ->
        exp_gained = Ash.Changeset.get_argument(changeset, :exp_gained)
        current_exp = Ash.Changeset.get_attribute(changeset, :total_exp) || 0
        Ash.Changeset.force_change_attribute(changeset, :total_exp, current_exp + exp_gained)
      end)
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if(relates_to_actor_via(:tenant_id))
    end

    policy action_type(:update) do
      authorize_if(actor_attribute_equals(:role, :admin))
      authorize_if(relates_to_actor_via(:user_id))
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :tenant_id, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :user_id, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :handle, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :editor_archetype, :atom do
      constraints(one_of: [:neovim, :vscode, :jetbrains, :emacs, :sublime])
      default(:neovim)
      public?(true)
    end

    attribute :main_language_rank, :integer do
      default(1)
      public?(true)
    end

    attribute :flow_multiplier, :float do
      default(1.0)
      public?(true)
    end

    attribute :total_exp, :integer do
      default(0)
      allow_nil?(false)
      public?(true)
    end

    attribute :mvp_score, :integer do
      default(0)
      public?(true)
    end

    attribute :familiar_type, :atom do
      constraints(one_of: [:claude, :copilot, :ollama, :gemini])
      default(:claude)
      public?(true)
    end

    attribute :familiar_level, :integer do
      default(1)
      public?(true)
    end

    attribute :total_commits_slain, :integer do
      default(0)
      public?(true)
    end

    timestamps()
  end

  calculations do
    calculate(:level, :integer, expr(floor(power(total_exp / 100.0, 0.5)) + 1))
  end

  relationships do
    has_many :loot_entries, CodeMantra.Ledger.LootLedger do
      destination_attribute(:player_profile_id)
    end
  end
end
