defmodule CodeMantra.Identity.RankCalculator do
  @moduledoc """
  Calculates player rank progression, remaining EXP to the next title,
  and handles the ceremonial audience with the King.
  """

  # Faxanadu-inspired developer rank titles and their required EXP thresholds
  @ranks [
    {1, "Novice Scripter", 0},
    {2, "Code Apprentice", 100},
    {3, "Function Wanderer", 400},
    {4, "Macro Weaver", 900},
    {5, "AST Sentinel", 1_600},
    {6, "BEAM Paladin", 2_500},
    {7, "Syntax Warden", 3_600},
    {8, "Architecture Lord", 4_900},
    {9, "Guru Scholar", 6_400},
    {10, "Grand Sovereign of the Tree", 8_100}
  ]

  @doc """
  Calculates a player's current status, remaining EXP to the next rank,
  and whether they must seek an audience with the King to be elevated.
  """
  def evaluate_progression(current_exp, current_rank) do
    # Determine what rank their raw EXP actually qualifies them for
    earned_rank = calculate_earned_rank(current_exp)
    {rank_num, title, _exp_req} = get_rank_info(earned_rank)

    # Next rank info
    {next_rank_num, next_title, next_exp_req} = get_rank_info(earned_rank + 1)
    exp_needed = max(next_exp_req - current_exp, 0)

    %{
      current_exp: current_exp,
      current_rank: current_rank,
      earned_rank: earned_rank,
      rank_title: title,
      next_rank_title: next_title,
      exp_needed_for_next_rank: exp_needed,
      king_audience_required?: earned_rank > current_rank
    }
  end

  @doc """
  Prints a Faxanadu-style ceremonial message from the King or Guru.
  """
  def format_king_dialogue(%{
        king_audience_required?: true,
        earned_rank: new_rank,
        rank_title: title
      }) do
    """
    👑 THE KING PROCLAIMS:
    "Ah, brave developer! Your total EXP has proven your mastery.
    By royal decree of the Realm, I bestow upon you Rank #{new_rank}: [ #{title} ]!
    Go forth, take your new title, and climb higher up the World Tree!"
    """
  end

  def format_king_dialogue(%{exp_needed_for_next_rank: exp, next_rank_title: next_title}) do
    """
    👑 THE KING SPEAKS:
    "You are not yet ready for advancement. You require #{exp} more EXP
    before I can elevate you to the rank of [ #{next_title} ].
    Return to your editor, slash more bugs, and present yourself once more!"
    """
  end

  # --- Internal Helpers ---

  defp calculate_earned_rank(exp) do
    @ranks
    |> Enum.filter(fn {_lvl, _title, req} -> exp >= req end)
    |> Enum.map(fn {lvl, _title, _req} -> lvl end)
    |> Enum.max(fn -> 1 end)
  end

  defp get_rank_info(rank_level) do
    Enum.find(@ranks, {10, "Grand Sovereign of the Tree", 8_100}, fn {lvl, _, _} ->
      lvl == rank_level
    end)
  end
end
