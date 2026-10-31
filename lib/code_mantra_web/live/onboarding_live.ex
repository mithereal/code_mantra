defmodule CodeMantraWeb.OnboardingLive do
  @moduledoc """
  WakaTime-Exclusive Onboarding Flow for Code::Mantra.
  Connects developer WakaTime telemetry to ingest historical coding hours
  and automatically forge initial developer experience and class stats.
  """
  use CodeMantraWeb, :live_view
  alias CodeMantra.Domain.PlayerProfile
  alias CodeMantra.Gamification

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:connecting, false)
      |> assign(:error_message, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("connect_wakatime", _params, socket) do
    # Initiate WakaTime Telemetry Handshake
    socket = assign(socket, :connecting, true)

    # Simulate API fetch of WakaTime stats (coding hours, languages, WPM)
    Process.send_after(self(), :process_wakatime_telemetry, 1500)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:process_wakatime_telemetry, socket) do
    user_id = "user_" <> (:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower))

    # Register Profile in Ash with telemetry awaiting Evaluation Daemon synthesis
    PlayerProfile
    |> Ash.Changeset.for_create(:register, %{
      id: user_id,
      username: "WakaVoyager",
      class_type: :pending_king_assignment,
      realm_id: "REALM-wakatime-synced"
    })
    |> Ash.create(domain: Gamification)

    {:noreply, push_navigate(socket, to: ~p"/dashboard/#{user_id}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-950 text-slate-100 font-mono flex items-center justify-center p-6">
      <div class="max-w-md w-full bg-slate-900 border border-slate-800 rounded-2xl p-8 shadow-2xl space-y-8 relative overflow-hidden">
        
    <!-- Top Accent Bar -->
        <div class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-amber-500 to-cyan-500">
        </div>
        
    <!-- Header -->
        <div class="text-center space-y-2">
          <h1 class="text-3xl font-extrabold tracking-wider text-amber-400">🛡️ CODE::MANTRA</h1>
          <p class="text-xs text-slate-400">DARK-FANTASY RPG DEVELOPMENT PLATFORM</p>
          <div class="inline-block bg-slate-800 text-amber-300 text-[10px] px-3 py-1 rounded-full border border-slate-700 font-bold">
            ⏱️ WAKATIME TELEMETRY LINK
          </div>
        </div>

        <%= if @error_message do %>
          <div class="bg-red-950/80 border border-red-800 text-red-300 text-xs p-3 rounded-lg text-center">
            ⚠️ #{@error_message}
          </div>
        <% end %>

        <%= if @connecting do %>
          <div class="py-12 text-center space-y-4">
            <div class="inline-block w-8 h-8 border-4 border-amber-500 border-t-transparent rounded-full animate-spin">
            </div>
            <p class="text-xs text-amber-300 font-bold tracking-wider animate-pulse">
              INGESTING WAKATIME CODING HOURS & LANGUAGES...
            </p>
          </div>
        <% else %>
          <div class="space-y-6">
            <p class="text-xs text-slate-400 text-center leading-relaxed">
              Link your WakaTime account to convert your historical coding hours, active languages, and editing cadence directly into starting RPG experience and level stats.
            </p>

            <button
              phx-click="connect_wakatime"
              class="w-full bg-gradient-to-r from-amber-600 to-amber-500 hover:from-amber-500 hover:to-amber-400 text-slate-950 font-extrabold py-3.5 px-6 rounded-xl transition-all duration-200 flex items-center justify-center gap-3 text-sm shadow-lg shadow-amber-500/10"
            >
              <span>⏱️</span>
              <span>CONNECT WAKATIME ACCOUNT</span>
            </button>
          </div>
        <% end %>

        <div class="text-center text-[10px] text-slate-500 pt-4 border-t border-slate-800/80">
          BEAM Engine v26.2 // Secure WakaTime Telemetry Bridge
        </div>
      </div>
    </div>
    """
  end
end
