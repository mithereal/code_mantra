defmodule CodeMantraWeb.MercenaryLeaderboardLive do
  use CodeMantraWeb, :live_view

  alias CodeMantra.Gamification
  alias CodeMantra.Realms

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CodeMantra.PubSub, "mercenary_bounties:global")
    end

    socket =
      socket
      |> assign(:top_mercenaries, list_top_mercenaries())
      |> assign(:open_bounties, list_active_bounties())

    {:ok, socket}
  end

  @impl true
  def handle_info({:bounty_updated, _payload}, socket) do
    {:noreply, assign(socket, open_bounties: list_active_bounties())}
  end

  # --- Helper Calculations for Stars & Forks ---

  def calculate_star_buff(star_count) do
    buff_percent = min(50, div(star_count, 100))
    "+#{buff_percent}% Gold & XP"
  end

  def calculate_bounty_value(base_gold, star_count, fork_count) do
    star_bonus = div(star_count, 10)
    fork_bonus = fork_count * 25
    base_gold + star_bonus + fork_bonus
  end

  defp list_top_mercenaries do
    # Queries top mercenaries ranked by cross-realm merits
    [
      %{id: "usr_881", handle: "elixir_ghost", merits: 42, gold_earned: 12_400},
      %{id: "usr_402", handle: "rust_blade", merits: 35, gold_earned: 9_850},
      %{id: "usr_109", handle: "beam_rider", merits: 29, gold_earned: 8_100}
    ]
  end

  defp list_active_bounties do
    [
      %{
        realm_id: "realm_ash_phoenix",
        repo_name: "phoenix_framework/phoenix",
        issue_title: "Fix LiveView WebSocket Memory Leak on Disconnect",
        stars: 21_500,
        forks: 2_800,
        base_gold: 500
      },
      %{
        realm_id: "realm_ex_doc",
        repo_name: "elixir-lang/ex_doc",
        issue_title: "Add Dynamic Search Indexing for Large Modules",
        stars: 1_400,
        forks: 310,
        base_gold: 250
      }
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
        <div class="p-6 bg-slate-900 text-slate-100 font-mono rounded-xl border border-slate-800">
          <div class="flex justify-between items-center mb-6">
            <h2 class="text-2xl font-bold text-amber-400 flex items-center gap-2">
              <span>⚔️</span> Mercenary Board: Open Source Bounties
            </h2>
            <span class="text-xs bg-amber-950 text-amber-300 border border-amber-800 px-3 py-1 rounded-full">
              Cross-Realm Bounties Active
            </span>
          </div>

          <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <!-- Active Open Source Bounties -->
            <div class="lg:col-span-2 space-y-4">
              <h3 class="text-sm uppercase tracking-wider text-slate-400 font-semibold mb-2">Available Quests</h3>
              <%= for bounty <- @open_bounties do %>
                <div class="p-4 bg-slate-800/60 border border-slate-700/80 rounded-lg hover:border-amber-500/50 transition">
                  <div class="flex justify-between items-start">
                    <div>
                      <span class="text-xs text-amber-400 font-bold"><%= bounty.repo_name %></span>
                      <h4 class="text-base font-semibold text-white mt-1"><%= bounty.issue_title %></h4>
                    </div>
                    <div class="text-right">
                      <span class="text-lg font-bold text-amber-300">
                        <%= calculate_bounty_value(bounty.base_gold, bounty.stars, bounty.forks) %> 💰
                      </span>
                      <div class="text-xs text-slate-400 mt-0.5">Base + Stars/Forks Bonus</div>
                    </div>
                  </div>

                  <!-- Repo Social Stats Impacting Dungeon Mechanics -->
                  <div class="mt-4 pt-3 border-t border-slate-700/50 flex items-center gap-4 text-xs text-slate-400">
                    <span class="flex items-center gap-1 text-yellow-400" title="Starlight Loot Buff">
                      ★ <%= bounty.stars %> (<%= calculate_star_buff(bounty.stars) %>)
                    </span>
                    <span class="flex items-center gap-1 text-cyan-400" title="Parallel Realm Fractures">
                      🍴 <%= bounty.forks %> Forks
                    </span>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Top Mercenary Adventurers -->
            <div class="bg-slate-800/40 p-4 rounded-lg border border-slate-800">
              <h3 class="text-sm uppercase tracking-wider text-slate-400 font-semibold mb-4">Top Mercenaries</h3>
              <div class="space-y-3">
                <%= for {merc, index} <- Enum.with_index(@top_mercenaries, 1) do %>
                  <div class="flex items-center justify-between p-2 rounded bg-slate-900/60">
                    <div class="flex items-center gap-3">
                      <span class="text-xs font-bold text-slate-500">#<%= index %></span>
                      <div>
                        <div class="text-sm font-semibold text-slate-200">@<%= merc.handle %></div>
                        <div class="text-xs text-emerald-400"><%= merc.merits %> Mercenary Merits</div>
                      </div>
                    </div>
                    <span class="text-xs text-amber-400 font-bold"><%= merc.gold_earned %> 💰</span>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
        """
  end
end