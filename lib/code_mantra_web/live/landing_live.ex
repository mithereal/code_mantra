defmodule CodeMantraWeb.LandingLive do
  use CodeMantraWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CodeMantra.PubSub, "world_crawl_feed")
      :timer.send_interval(3000, self(), :tick_crawl_simulation)
    end

    initial_world = %{
      realm_id: "REALM-4aef81",
      biome: "The Obsidian Monolith of Rust Core",
      active_crawl_nodes: [
        %{
          user: "Jason Clark",
          class: "Pointer-Smith",
          lang: "Rust",
          action: "Compiling zero-cost abstractions...",
          x: 15,
          y: 35
        },
        %{
          user: "ElixirWizard",
          class: "Grand Alchemist",
          lang: "Elixir",
          action: "Supervising Actor state...",
          x: 48,
          y: 22
        },
        %{
          user: "TypeScriptShadow",
          class: "Web Rogue",
          lang: "TypeScript",
          action: "Evading strict-type compiler dragon...",
          x: 75,
          y: 65
        }
      ],
      total_active_crawlers: 142
    }

    {:ok, assign(socket, page_title: "Code::Mantra — Title Ritual", world: initial_world)}
  end

  @impl true
  def handle_info(:tick_crawl_simulation, socket) do
    current_world = socket.assigns.world

    updated_nodes =
      Enum.map(current_world.active_crawl_nodes, fn node ->
        %{
          node
          | x: rem(node.x + :rand.uniform(7) - 3 + 100, 100),
            y: rem(node.y + :rand.uniform(7) - 3 + 100, 100)
        }
      end)

    {:noreply, assign(socket, world: %{current_world | active_crawl_nodes: updated_nodes})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative min-h-screen bg-slate-950 text-emerald-400 font-mono overflow-hidden selection:bg-emerald-500 selection:text-slate-950">
      
    <!-- BACKGROUND: Procedural World Crawl Grid -->
      <div class="absolute inset-0 pointer-events-none overflow-hidden opacity-30">
        <div class="absolute inset-0 bg-[radial-gradient(#10b981_1px,transparent_1px)] [background-size:32px_32px]">
        </div>
        <div class="relative h-full w-full">
          <%= for node <- @world.active_crawl_nodes do %>
            <div
              class="absolute transition-all duration-1000 ease-linear flex flex-col items-center"
              style={"top: #{node.y}%; left: #{node.x}%;"}
            >
              <div class="bg-slate-900 border border-emerald-600/50 text-emerald-400 px-2 py-0.5 rounded text-[9px]">
                <span class="text-amber-400 font-bold">{node.user}</span> ({node.lang})
              </div>
              <div class="w-2.5 h-2.5 bg-emerald-400 rounded-full animate-ping mt-1"></div>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- FOREGROUND: RPG Title Screen -->
      <div class="relative z-10 min-h-screen flex flex-col items-center justify-between p-6 md:p-12 max-w-5xl mx-auto text-center">
        <div class="w-full flex items-center justify-between text-xs text-slate-500 border-b border-emerald-900/60 pb-4">
          <div>
            REALM: <span class="text-emerald-400 font-bold">{@world.realm_id}</span> ({@world.biome})
          </div>
          <div class="space-x-4">
            <.link navigate={~p"/about"} class="text-amber-400 hover:underline">
              👤 CREATOR STORY
            </.link>
          </div>
        </div>

        <div class="space-y-6 my-auto max-w-2xl bg-slate-900/80 border-2 border-emerald-700/80 p-8 md:p-12 rounded-xl shadow-[0_0_50px_rgba(16,185,129,0.15)] backdrop-blur-md">
          <div class="space-y-2">
            <div class="text-xs uppercase tracking-[0.3em] text-amber-400 font-bold">
              BEAM Concurrency Telemetry RPG
            </div>
            <h1 class="text-5xl md:text-7xl font-black tracking-widest text-slate-100">
              CODE::<span class="text-emerald-400">MANTRA</span>
            </h1>
            <p class="text-xs text-slate-400 italic">
              "Where complexity forges the world, and every keystroke writes thy legend."
            </p>
          </div>

          <div class="border-t border-emerald-900/80 pt-6 space-y-4">
            <.link
              navigate={~p"/onboarding"}
              class="inline-block bg-emerald-600 hover:bg-emerald-500 text-slate-950 font-extrabold px-8 py-4 rounded text-base transition shadow-xl hover:scale-105"
            >
              [ START RITUAL: CONNECT IDE ]
            </.link>
            <div class="flex justify-center gap-6 text-xs text-slate-400 pt-2">
              <.link navigate={~p"/about"} class="hover:text-emerald-300">⚡ System Manifesto</.link>
              <span>•</span>
              <.link navigate={~p"/about"} class="text-amber-400 hover:underline">
                ☕ Support Jason Clark
              </.link>
            </div>
          </div>
        </div>

        <div class="w-full border-t border-emerald-900/60 pt-4 flex flex-col md:flex-row items-center justify-between text-xs text-slate-500 gap-2">
          <div>
            ONLINE CRAWLERS:
            <span class="text-emerald-400 font-bold">{@world.total_active_crawlers}</span>
          </div>
          <div>ARCHITECT: <span class="text-amber-400">Jason Clark (Tucson, AZ)</span></div>
          <div>ENGINE: Elixir / Phoenix BEAM v1.7</div>
        </div>
      </div>
    </div>
    """
  end
end
