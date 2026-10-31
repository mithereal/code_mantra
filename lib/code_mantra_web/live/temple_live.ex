defmodule CodeMantraWeb.TempleLive do
  use CodeMantraWeb, :live_view

  alias CodeMantra.Identity.PlayerProfile
  alias CodeMantra.Identity.RankCalculator

  @impl true
  def mount(_params, _session, socket) do
    # Sample player profile fetch (normally scoped to current_user & tenant)
    exp = 1250
    current_rank = 3

    progression = RankCalculator.evaluate_progression(exp, current_rank)
    king_message = RankCalculator.format_king_dialogue(progression)

    {:ok,
     assign(socket,
       total_exp: exp,
       current_rank: current_rank,
       progression: progression,
       king_message: king_message,
       show_audience: progression.king_audience_required?
     )}
  end

  @impl true
  def handle_event("petition_king", _params, socket) do
    progression = socket.assigns.progression

    # Execute Ash promotion action as the King's state authority
    case Ash.update(socket.assigns.player_profile, :promote_rank, %{
           new_rank: progression.earned_rank
         }) do
      {:ok, updated_profile} ->
        new_progression =
          RankCalculator.evaluate_progression(
            updated_profile.total_exp,
            updated_profile.main_language_rank
          )

        {:noreply,
         assign(socket,
           current_rank: updated_profile.main_language_rank,
           progression: new_progression,
           king_message:
             "👑 THE KING HAS SEALED YOUR RANK! GO FORTH, #{new_progression.rank_title}!",
           show_audience: false
         )}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "The King's scribe failed to record your rank.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto p-6 bg-slate-950 text-slate-100 rounded-xl border border-amber-600/40 shadow-2xl font-mono select-none">
      
    <!-- TEMPLE ALTAR HEADER -->
      <div class="text-center border-b border-slate-800 pb-4 mb-6">
        <h1 class="text-3xl font-bold text-amber-400 tracking-wider">🏰 THE TEMPLE OF THE KING</h1>
        <p class="text-xs text-slate-400 mt-1">
          Present your EXP metrics to receive royal decree and rank advancement.
        </p>
      </div>
      
    <!-- PLAYER STATUS BOX -->
      <div class="grid grid-cols-3 gap-4 mb-6 bg-slate-900/80 p-4 rounded-lg border border-slate-800 text-center">
        <div>
          <div class="text-xs text-slate-400">TOTAL EXP</div>
          <div class="text-xl font-bold text-emerald-400">{@total_exp} XP</div>
        </div>
        <div>
          <div class="text-xs text-slate-400">CURRENT RANK</div>
          <div class="text-xl font-bold text-amber-300">Rank {@current_rank}</div>
        </div>
        <div>
          <div class="text-xs text-slate-400">EXP TO NEXT RANK</div>
          <div class="text-xl font-bold text-cyan-400">
            {@progression.exp_needed_for_next_rank} XP
          </div>
        </div>
      </div>
      
    <!-- KING's DIALOGUE & AUDIENCE WINDOW (FAXANADU STYLE) -->
      <div class="relative bg-blue-950/90 border-4 border-amber-500/80 rounded-lg p-5 shadow-2xl">
        <div class="flex items-start gap-4">
          <div class="text-5xl">👑</div>
          <div class="flex-1">
            <div class="text-xs font-bold text-amber-400 mb-2 uppercase tracking-widest">
              Royal Decree
            </div>
            <p class="text-sm text-slate-100 leading-relaxed whitespace-pre-line font-medium">
              {@king_message}
            </p>
          </div>
        </div>
        
    <!-- PROMOTION ACTION BUTTON -->
        <%= if @show_audience do %>
          <div class="mt-4 text-right">
            <button
              phx-click="petition_king"
              class="px-5 py-2.5 bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 font-bold rounded shadow-lg border border-amber-300 transition-all transform active:scale-95 text-xs uppercase tracking-wider"
            >
              📜 Kneel & Receive Rank {@progression.earned_rank} Title
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
