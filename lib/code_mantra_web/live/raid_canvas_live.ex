defmodule CodeMantraWeb.RaidCanvasLive do
  use CodeMantraWeb, :live_view

  alias CodeMantra.Dungeon.BossEngine

  @impl true
  def mount(%{"pr_id" => pr_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CodeMantra.PubSub, "raid:#{pr_id}")
    end

    # Demo initial state for testing/mounting
    {:ok, sample_boss} =
      BossEngine.manifest_boss(%{
        "title" => "Refactor Multitenant Ash Ledger",
        "additions" => 420,
        "deletions" => 180,
        "changed_files" => 12,
        "node_id" => pr_id
      })

    sample_party = [
      %{
        usr: "jason_c",
        class: "Neovim Blademaster",
        flow: 2.8,
        familiar: "Claude (Lvl 25)",
        hp: 100
      },
      %{usr: "alex_dev", class: "VS Code Mage", flow: 1.9, familiar: "Copilot (Lvl 12)", hp: 85}
    ]

    {:ok,
     assign(socket,
       boss: sample_boss,
       party: sample_party,
       combat_log: ["Raid encounter initiated!"]
     )}
  end

  @impl true
  def handle_info({:boss_updated, updated_boss}, socket) do
    {:noreply, assign(socket, :boss, updated_boss)}
  end

  @impl true
  def handle_info({:combat_event, message}, socket) do
    updated_log = [message | Enum.take(socket.assigns.combat_log, 4)]
    {:noreply, assign(socket, :combat_log, updated_log)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-6 bg-slate-950 text-slate-100 rounded-xl border border-red-500/40 shadow-2xl font-mono">
      <!-- HEADER / BOSS TITLE -->
      <div class="flex justify-between items-center mb-4 border-b border-slate-800 pb-3">
        <div>
          <span class="text-xs uppercase tracking-widest text-red-400 font-bold">
            PR Raid Encounter
          </span>
          <h1 class="text-2xl font-bold text-slate-100">{@boss.boss_name}</h1>
        </div>
        <div class="text-right">
          <%= if @boss.is_enraged do %>
            <span class="inline-block px-3 py-1 bg-red-600 text-slate-950 text-xs font-bold rounded animate-pulse">
              ⚠️ CI BUILD ENRAGED (+50% DMG)
            </span>
          <% else %>
            <span class="inline-block px-3 py-1 bg-amber-500/20 text-amber-400 text-xs font-semibold rounded border border-amber-500/30">
              PHASE: {humanize_phase(@boss.phase)}
            </span>
          <% end %>
        </div>
      </div>
      
    <!-- BOSS HEALTH BAR -->
      <div class="mb-8">
        <div class="flex justify-between text-sm mb-1">
          <span class="text-red-400 font-bold">BOSS INTEGRITY</span>
          <span class="text-slate-400">{@boss.current_hp} / {@boss.total_hp} HP</span>
        </div>
        <div class="w-full h-6 bg-slate-900 rounded-full border border-red-900/60 overflow-hidden p-0.5 shadow-inner">
          <div
            class="h-full bg-gradient-to-r from-red-600 to-amber-500 rounded-full transition-all duration-500 ease-out"
            style={"width: #{hp_percentage(@boss)}%"}
          >
          </div>
        </div>
        <div class="flex justify-between text-xs text-slate-500 mt-1">
          <span>Armor: {@boss.armor}</span>
          <span>Loot Drop: {String.upcase(to_string(@boss.rewards.loot_tier))}</span>
        </div>
      </div>
      
    <!-- RAID PARTY STATUS GRID -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <%= for member <- @party do %>
          <div class="p-3 bg-slate-900/80 rounded border border-slate-800 flex justify-between items-center">
            <div>
              <div class="text-sm font-bold text-amber-300">@{member.usr}</div>
              <div class="text-xs text-slate-400">{member.class}</div>
              <div class="text-xs text-slate-500">Companion: {member.familiar}</div>
            </div>
            <div class="text-right">
              <span class="text-xs text-emerald-400 bg-emerald-950/60 px-2 py-0.5 rounded border border-emerald-800/40">
                {member.flow}x Flow
              </span>
            </div>
          </div>
        <% end %>
      </div>
      
    <!-- COMBAT LOG -->
      <div class="p-3 bg-slate-900/50 rounded border border-slate-800/80">
        <div class="text-xs text-slate-500 mb-1 border-b border-slate-800 pb-1">
          COMBAT LOG STREAM
        </div>
        <ul class="space-y-1 text-xs text-slate-300">
          <%= for log <- @combat_log do %>
            <li class="flex items-center gap-2">
              <span class="text-red-400">⚔️</span> {log}
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  defp hp_percentage(boss) do
    max(round(boss.current_hp / boss.total_hp * 100), 0)
  end

  defp humanize_phase(:phase_1_overmind), do: "1 - Overmind Diff"
  defp humanize_phase(:phase_2_refactor_adds), do: "2 - Linter Adds"
  defp humanize_phase(:phase_3_merge_ready), do: "3 - Final Merge Strike"
end
