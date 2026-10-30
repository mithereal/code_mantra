defmodule CodeMantraWeb.StreamLive do
  use CodeMantraWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CodeMantra.PubSub, "world_crawl_feed")
    end

    {:ok, assign(socket, page_title: "Code::Mantra — OBS Stream Overlay", active_events: [])}
  end

  @impl true
  def handle_info({:boss_spawned, boss}, socket) do
    events = [boss | socket.assigns.active_events] |> Enum.take(5)
    {:noreply, assign(socket, active_events: events)}
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen w-screen bg-transparent text-emerald-400 font-mono p-8 overflow-hidden flex flex-col justify-between">

      <!-- Top OBS Banner Overlay -->
      <div class="flex items-center justify-between bg-slate-950/80 border border-emerald-800/80 p-4 rounded-lg backdrop-blur shadow-2xl">
        <div class="flex items-center space-x-3">
          <span class="w-3 h-3 rounded-full bg-emerald-400 animate-ping"></span>
          <span class="text-sm font-bold text-amber-400">CODE::MANTRA LIVE STREAM OVERLAY</span>
        </div>
        <div class="text-xs text-slate-400">
          BEAM Concurrency Engine • Active World Feed
        </div>
      </div>

      <!-- Active Boss Alerts Stream -->
      <div class="w-96 space-y-3 self-end">
        <%= for event <- @active_events do %>
          <div class="bg-rose-950/90 border border-rose-600 text-rose-200 p-4 rounded-lg shadow-2xl animate-bounce">
            <div class="text-xs font-bold text-rose-400 uppercase tracking-widest">⚠️ Raid Boss Spawned</div>
            <div class="text-base font-black"><%= event.name %></div>
            <div class="text-xs text-slate-300 mt-1">Origin: <%= event.origin_file %></div>
          </div>
        <% end %>
      </div>

      <!-- Bottom Ticker -->
      <div class="bg-slate-950/90 border border-emerald-900 p-3 rounded text-xs text-emerald-300 flex justify-between items-center">
        <span>STATUS: Connected to DUNGEON_ORCHESTRATOR</span>
        <span class="text-slate-500">Architect: Jason Clark (Tucson, AZ)</span>
      </div>

    </div>
    """
  end
end