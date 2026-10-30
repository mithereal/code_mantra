defmodule CodeMantraWeb.DashboardLive do
  @moduledoc """
  Real-time developer dashboard UI for Code::Mantra.
  Subscribes to player telemetry broadcasts and world boss raid feeds.
  """
  use CodeMantraWeb, :live_view

  @impl true
  def mount(%{"user_id" => user_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CodeMantra.PubSub, "player:#{user_id}")
      Phoenix.PubSub.subscribe(CodeMantra.PubSub, "world_crawl_feed")
    end

    # Fetch initial profile or default state
    profile = case Ash.get(CodeMantra.Domain.PlayerProfile, user_id) do
      {:ok, p} when not is_nil(p) -> p
      _ -> %{username: "Novice Coder", level: 1, xp: 0, gold: 100, tier_badge: "D", royal_title: "The Novice Script-Knight"}
    end

    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:profile, profile)
      |> assign(:boss_hp, 250_000)
      |> assign(:boss_status, "Dormant")
      |> assign(:combat_log, [])

    {:ok, socket}
  end

  @impl true
  def handle_info({:xp_gained, data}, socket) do
    current_profile = socket.assigns.profile
    updated_xp = current_profile.xp + data.xp
    updated_gold = current_profile.gold + data.gold
    updated_level = max(1, div(updated_xp, 1000))

    updated_profile = %{current_profile | xp: updated_xp, gold: updated_gold, level: updated_level}

    log_entry = "⚡ Gained #{data.xp} XP & #{data.gold} Shards (WPM: #{data.wpm})"

    socket =
      socket
      |> assign(:profile, updated_profile)
      |> update(:combat_log, fn log -> [log_entry | log] |> Enum.take(5) end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:boss_spawned, data}, socket) do
    socket =
      socket
      |> assign(:boss_hp, data.hp)
      |> assign(:boss_status, "AWOKEN (#{data.realm_id})")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:boss_hp_updated, data}, socket) do
    {:noreply, assign(socket, :boss_hp, data.current_hp)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-950 text-slate-100 font-mono p-6">
      <!-- Header Banner -->
      <header class="flex justify-between items-center border-b border-slate-800 pb-4 mb-6">
        <div>
          <h1 class="text-2xl font-bold tracking-wider text-amber-400">🛡️ CODE::MANTRA OVERLAY</h1>
          <p class="text-xs text-slate-400">Dark-Fantasy RPG Development Terminal</p>
        </div>
        <div class="flex items-center gap-4 bg-slate-900 border border-slate-800 px-4 py-2 rounded-lg">
          <div>
            <span class="text-xs text-slate-400 block">GOLD WALLET</span>
            <span class="text-amber-300 font-bold">🪙 #{@profile.gold} Shards</span>
          </div>
        </div>
      </header>

      <!-- Main Grid Layout -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">

        <!-- Column 1 & 2: Character Sheet & Live Feed -->
        <div class="md:col-span-2 space-y-6">

          <!-- Character Card -->
          <div class="bg-slate-900 border border-slate-800 rounded-xl p-6 shadow-xl relative overflow-hidden">
            <div class="absolute top-0 right-0 bg-amber-500/10 text-amber-400 text-xs px-3 py-1 rounded-bl-lg font-bold border-l border-b border-amber-500/20">
              TIER: #{@profile.tier_badge}
            </div>

            <div class="space-y-2">
              <span class="text-xs tracking-widest text-indigo-400 font-semibold uppercase">Level #{@profile.level} Developer</span>
              <h2 class="text-xl font-bold text-slate-100">#{@profile.username}</h2>
              <p class="text-sm italic text-amber-200/90 font-serif">"#{Map.get(@profile, :royal_title, "The Unblemished Canvas")}"</p>
            </div>

            <!-- XP Progress Bar -->
            <div class="mt-6 space-y-1">
              <div class="flex justify-between text-xs text-slate-400">
                <span>XP PROGRESS</span>
                <span>#{@profile.xp} / #{@profile.level * 1000} XP</span>
              </div>
              <div class="w-full bg-slate-950 rounded-full h-3 border border-slate-800 overflow-hidden">
                <div class="bg-gradient-to-r from-amber-600 to-amber-400 h-full transition-all duration-300" style={"width: #{min(100, (@profile.xp / max(1, @profile.level * 1000)) * 100)}%"}></div>
              </div>
            </div>
          </div>

          <!-- Combat & Telemetry Log -->
          <div class="bg-slate-900 border border-slate-800 rounded-xl p-6 shadow-xl">
            <h3 class="text-sm font-bold text-slate-300 uppercase tracking-wider mb-4 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span> Telemetry & Combat Feed
            </h3>
            <div class="bg-slate-950 rounded-lg p-4 border border-slate-800/80 h-40 overflow-y-auto space-y-2 font-mono text-xs">
              <%= if Enum.empty?(@combat_log) do %>
                <p class="text-slate-600 italic">// Waiting for editor telemetry stream...</p>
              <% else %>
                <%= for entry <- @combat_log do %>
                  <p class="text-emerald-400"><%= entry %></p>
                <% end %>
              <% end %>
            </div>
          </div>

        </div>

        <!-- Column 3: World Boss Raid State -->
        <div class="space-y-6">
          <div class="bg-gradient-to-b from-red-950/40 to-slate-900 border border-red-900/40 rounded-xl p-6 shadow-xl">
            <div class="flex justify-between items-start mb-4">
              <h3 class="text-sm font-bold text-red-400 uppercase tracking-wider">World Boss Threat</h3>
              <span class="text-xs bg-red-900/40 text-red-300 px-2 py-0.5 rounded border border-red-700/50"><%= @boss_status %></span>
            </div>

            <div class="space-y-4">
              <div>
                <h4 class="text-lg font-bold text-slate-100">The Monolith King</h4>
                <p class="text-xs text-slate-400">Phase: Syntactical Corruption</p>
              </div>

              <!-- Boss HP Pool -->
              <div class="space-y-1">
                <div class="flex justify-between text-xs text-red-300">
                  <span>BOSS HP</span>
                  <span>#{@boss_hp} / 250,000</span>
                </div>
                <div class="w-full bg-slate-950 rounded-full h-3 border border-red-900/50 overflow-hidden">
                  <div class="bg-gradient-to-r from-red-700 to-red-500 h-full transition-all duration-300" style={"width: #{min(100, (@boss_hp / 250_000) * 100)}%"}></div>
                </div>
              </div>

              <div class="pt-2 text-xs text-slate-400 border-t border-slate-800">
                <p>💡 Tip: Push clean validation tests and resolve git fractures to reduce boss armor worldwide.</p>
              </div>
            </div>
          </div>

          <!-- Quick Apothecary Reference -->
          <div class="bg-slate-900 border border-slate-800 rounded-xl p-6 shadow-xl">
            <h3 class="text-sm font-bold text-slate-300 uppercase tracking-wider mb-3">Active Buffs & Shop</h3>
            <ul class="space-y-2 text-xs text-slate-400">
              <li class="flex justify-between items-center py-1 border-b border-slate-800/60">
                <span>🧪 Caffeine Tincture</span>
                <span class="text-amber-400">150 Gold</span>
              </li>
              <li class="flex justify-between items-center py-1 border-b border-slate-800/60">
                <span>🧹 Garbage Collector Elixir</span>
                <span class="text-amber-400">300 Gold</span>
              </li>
              <li class="flex justify-between items-center py-1">
                <span>⚡ Pipeline Defibrillator</span>
                <span class="text-amber-400">500 Gold</span>
              </li>
            </ul>
          </div>

        </div>

      </div>
    </div>
    """
  end
end