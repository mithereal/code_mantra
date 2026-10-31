defmodule CodeMantra.Gamification do
  @moduledoc """
  Ash Domain module exposing core gamification resources including SharedRanks.
  """
  use Ash.Domain,
    resources: [
      CodeMantra.Domain.Guild,
      CodeMantra.Domain.PlayerProfile,
      CodeMantra.Domain.ArmoryItem,
      CodeMantra.Domain.RaidEncounter,
      CodeMantra.Domain.SkillNode,
      CodeMantra.Domain.SharedRank,
      CodeMantra.Domain.MonolithKing
    ]
end
