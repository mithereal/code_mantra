defmodule CodeMantra.Dungeon.DifficultyScaler do
  @moduledoc """
  Calculates monster scaling factors based on whether a Realm
  is a corporate enterprise or an independent open-source project.
  """

  @spec calculate_boss_hp(map(), integer()) :: integer()
  def calculate_boss_hp(realm_meta, base_hp) do
    case realm_meta.type do
      :corporate_org ->
        # Scale heavily by active team size
        active_dev_count = max(1, realm_meta.active_contributors_count)
        round(base_hp * (1.0 + active_dev_count * 0.5))

      :personal_open_source ->
        # Cap scaling so solo maintainers or small open-source parties aren't overwhelmed
        active_dev_count = max(1, realm_meta.active_contributors_count)
        round(base_hp * (1.0 + active_dev_count * 0.15))
    end
  end
end
