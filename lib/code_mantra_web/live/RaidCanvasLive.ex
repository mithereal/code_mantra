defmodule CodeMantraWeb.RaidCanvasLive do
  use CodeMantraWeb, :live_view

  @impl true
  def mount(%{"pr_id" => pr_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CodeMantra.PubSub, "raid:#{pr_id}")
    end

    # Initial state starts in dedicated FF6 battle mode upon PR trigger
    {:ok,
     assign(socket,
       view_mode: :ff6_battle,
       transition_anim: :flash,
       boss: %{
         name: "The Monolithic Behemoth",
         hp: 2150,
         max_hp: 2500,
         phase: "Phase 2: Refactor Adds",
         sprite: "behemoth_sprite.gif"
       },
       party: [
         %{name: "Jason (Neovim)", hp: 340, max_hp: 340, mp: 95, max_mp: 100, status: :active},
         %{name: "Alex (VS Code)", hp: 280, max_hp: 300, mp: 120, max_mp: 120, status: :active}
       ],
       battle_log: [
         "Encounter triggered by PR #42!",
         "The Monolithic Behemoth blocks the merge pipeline!"
       ]
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative w-full max-w-4xl mx-auto h-[500px] bg-slate-950 border-4 border-slate-700 rounded-lg shadow-2xl overflow-hidden font-mono select-none flex flex-col justify-between p-4 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-slate-900 via-slate-950 to-black">
      
    <!-- SCREEN FLASH TRANSITION OVERLAY -->
      <%= if @transition_anim do %>
        <div class="absolute inset-0 bg-white animate-ping opacity-20 pointer-events-none"></div>
      <% end %>
      
    <!-- UPPER BATTLEFIELD: BOSS ARENA -->
      <div class="flex-1 flex flex-col items-center justify-center relative border-b-2 border-blue-900/40 pb-4">
        <!-- Boss HP Bar (Classic JRPG Top Banner) -->
        <div class="absolute top-2 w-64 bg-slate-900/90 border border-blue-500/50 p-1.5 rounded text-center shadow-lg">
          <div class="text-xs text-amber-400 font-bold mb-1">{@boss.name}</div>
          <div class="w-full h-2 bg-slate-950 rounded-full overflow-hidden border border-slate-800">
            <div
              class="h-full bg-red-600 transition-all duration-300"
              style={"width: #{(@boss.hp / @boss.max_hp) * 100}%"}
            >
            </div>
          </div>
        </div>
        
    <!-- Boss Sprite Container -->
        <div class="text-center animate-bounce duration-1000 mt-6">
          <div class="text-6xl mb-2">🐉⚔️</div>
          <span class="text-xs text-red-400 bg-red-950/80 px-2 py-0.5 rounded border border-red-800 uppercase tracking-widest">
            {@boss.phase}
          </span>
        </div>
      </div>
      
    <!-- LOWER SECTION: BATTLE LOG & CLASSIC FF6 BLUE WINDOW MENU -->
      <div class="grid grid-cols-3 gap-3 h-40">
        
    <!-- BATTLE LOG STREAM (Left Box) -->
        <div class="col-span-2 bg-blue-950/40 border-2 border-blue-600/70 rounded p-3 overflow-y-auto text-xs text-slate-200 shadow-inner">
          <div class="text-blue-400 font-bold mb-1 border-b border-blue-900/50 pb-0.5">
            BATTLE LOG
          </div>
          <ul class="space-y-1">
            <%= for log <- @battle_log do %>
              <li class="flex items-center gap-1.5">
                <span class="text-amber-400">▶</span> {log}
              </li>
            <% end %>
          </ul>
        </div>
        
    <!-- CLASSIC JRPG COMMAND WINDOW (Right Box) -->
        <div class="bg-blue-950/80 border-2 border-blue-500 rounded p-3 flex flex-col justify-between shadow-2xl">
          <div class="text-xs text-amber-300 font-bold border-b border-blue-800 pb-1 text-center">
            PARTY COMMANDS
          </div>
          <div class="space-y-1 text-xs text-slate-100 font-semibold">
            <div class="hover:text-amber-400 cursor-pointer flex items-center gap-1">
              ⚔️ Attack (Commit)
            </div>
            <div class="hover:text-amber-400 cursor-pointer flex items-center gap-1">
              ✨ Cast Spell (AI Prompt)
            </div>
            <div class="hover:text-amber-400 cursor-pointer flex items-center gap-1">
              📜 Use Mantra (Guru)
            </div>
            <div class="hover:text-amber-400 cursor-pointer flex items-center gap-1">
              🛡️ Defend (CI Check)
            </div>
          </div>
        </div>
      </div>
      
    <!-- PARTY STATUS HUD (Bottom Banner Overlay) -->
      <div class="grid grid-cols-2 gap-2 mt-2 pt-2 border-t border-slate-800/80 text-xs">
        <%= for member <- @party do %>
          <div class="bg-slate-900/80 border border-slate-700/60 p-2 rounded flex justify-between items-center">
            <span class="font-bold text-amber-300">{member.name}</span>
            <div class="space-x-3 text-slate-300">
              <span>HP: <strong class="text-emerald-400">{member.hp}/{member.max_hp}</strong></span>
              <span>MP: <strong class="text-cyan-400">{member.mp}/{member.max_mp}</strong></span>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
