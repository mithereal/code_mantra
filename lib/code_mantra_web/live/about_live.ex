defmodule CodeMantraWeb.AboutLive do
  use CodeMantraWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "System Manifesto — Code::Mantra")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-950 text-emerald-400 font-mono p-6 md:p-12 selection:bg-emerald-500 selection:text-slate-950">
      <div class="max-w-4xl mx-auto space-y-12 bg-slate-900/90 border-2 border-emerald-800/80 p-8 md:p-12 rounded-xl shadow-[0_0_50px_rgba(16,185,129,0.1)] backdrop-blur-md">
        
    <!-- Header Nav -->
        <div class="flex items-center justify-between border-b border-emerald-900/80 pb-6 text-xs">
          <.link navigate={~p"/"} class="text-slate-400 hover:text-emerald-300 transition">
            ← RETURN TO TITLE
          </.link>
          <div class="text-amber-400 font-bold uppercase tracking-widest">
            System Manifesto & Architecture
          </div>
        </div>
        
    <!-- Title Section -->
        <div class="space-y-4">
          <div class="text-xs uppercase tracking-[0.3em] text-amber-400 font-bold">
            The BEAM Concurrency Telemetry Engine
          </div>
          <h1 class="text-4xl md:text-5xl font-black text-slate-100 tracking-wider">
            CODE::<span class="text-emerald-400">MANTRA</span> ARCHITECTURE
          </h1>
          <p class="text-sm text-slate-300 leading-relaxed">
            Code::Mantra transforms high-throughput IDE telemetry into a persistent dark-fantasy RPG. By leveraging the actor model on the BEAM virtual machine, incoming keystroke buffers are evaluated, filtered for anti-cheat anomalies, and translated into world state changes in real time.
          </p>
        </div>
        
    <!-- 6 Actor Daemons Breakdown -->
        <div class="space-y-6 border-t border-emerald-900/80 pt-8">
          <h2 class="text-xl font-bold text-amber-400 tracking-wide">⚡ The 6 Core Actor Daemons</h2>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 text-xs">
            <div class="bg-slate-950/80 border border-emerald-900 p-5 rounded-lg space-y-2">
              <div class="text-emerald-300 font-bold text-sm">1. CLIENT_SOCKET</div>
              <p class="text-slate-400">
                Manages active WebSocket connections from VS Code and Neovim extensions, ingesting 250ms sliding window telemetry batches.
              </p>
            </div>

            <div class="bg-slate-950/80 border border-emerald-900 p-5 rounded-lg space-y-2">
              <div class="text-emerald-300 font-bold text-sm">2. EVALUATION_DAEMON</div>
              <p class="text-slate-400">
                Parses abstract syntax tree (AST) complexity, computes cyclomatic complexity ($M$), and assigns language paradigms.
              </p>
            </div>

            <div class="bg-slate-950/80 border border-emerald-900 p-5 rounded-lg space-y-2">
              <div class="text-emerald-300 font-bold text-sm">3. PROGRESSION_BALANCER</div>
              <p class="text-slate-400">
                Applies Shannon Entropy filters to block macro spam and AI copy-paste bursts while awarding XP and gold shards.
              </p>
            </div>

            <div class="bg-slate-950/80 border border-emerald-900 p-5 rounded-lg space-y-2">
              <div class="text-emerald-300 font-bold text-sm">4. PERSISTENCE_DAEMON</div>
              <p class="text-slate-400">
                Buffers in-memory state deltas and flushes Base32 runic state checkpoints down to PostgreSQL at interval checkpoints.
              </p>
            </div>

            <div class="bg-slate-950/80 border border-emerald-900 p-5 rounded-lg space-y-2">
              <div class="text-emerald-300 font-bold text-sm">5. DUNGEON_ORCHESTRATOR</div>
              <p class="text-slate-400">
                Monitors aggregate repository code health and procedurally spawns raid bosses and compile-time hazards.
              </p>
            </div>

            <div class="bg-slate-950/80 border border-emerald-900 p-5 rounded-lg space-y-2">
              <div class="text-emerald-300 font-bold text-sm">6. STREAM_ANIMATOR</div>
              <p class="text-slate-400">
                Drives 10 FPS vector coordinate updates for OBS overlays and live web-based world crawl feeds.
              </p>
            </div>
          </div>
        </div>
        
    <!-- Creator Spotlight -->
        <div class="border-t border-emerald-900/80 pt-8 space-y-4">
          <h2 class="text-xl font-bold text-amber-400 tracking-wide">☕ Creator Spotlight</h2>
          <div class="bg-slate-950/80 border border-emerald-900/80 p-6 rounded-lg flex flex-col md:flex-row justify-between items-start md:items-center gap-4 text-xs">
            <div class="space-y-1">
              <div class="text-slate-200 font-bold text-sm">Engineered by Jason Clark</div>
              <div class="text-slate-400">
                Crafted in Tucson, Arizona • Focused on Elixir, Phoenix, Ash Framework, and Systems Architecture.
              </div>
            </div>
            <div class="flex gap-4">
              <.link
                navigate={~p"/onboarding"}
                class="bg-emerald-600 hover:bg-emerald-500 text-slate-950 font-bold px-4 py-2 rounded transition"
              >
                Connect IDE
              </.link>
            </div>
          </div>
        </div>
        
    <!-- Footer Nav -->
        <div class="border-t border-emerald-900/80 pt-6 flex justify-between items-center text-xs text-slate-500">
          <div>CODE::MANTRA v1.7.0</div>
          <.link navigate={~p"/"} class="text-amber-400 hover:underline">
            ← Return to Title Screen
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
