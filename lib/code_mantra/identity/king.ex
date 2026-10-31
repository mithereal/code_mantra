defmodule CodeMantra.Identity.King do
  @moduledoc "The King: Assembles full developer telemetry for the Priest."

  alias CodeMantra.Identity.Priest

  def issue_mantra(user_id, tenant_id \\ "AZ-TUC") do
    full_actor_state = %{
      usr: user_id,
      # Main Language Rank
      rank: 18,
      # Class Weapon
      editor: :neovim,
      # Flow Multiplier
      flow: 2.8,
      # MVP Score
      mvp: 99,
      # AI Familiar Type
      familiar: :claude,
      # Familiar Bonding Level
      fam_lvl: 25,
      ts: DateTime.utc_now() |> DateTime.to_unix()
    }

    Priest.bless_and_sign(tenant_id, full_actor_state)
  end
end
