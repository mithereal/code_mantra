defmodule CodeMantraWeb.ManagerDashboardLive do
  use CodeMantraWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CodeMantra.PubSub, "org_metrics:#{socket.assigns.tenant}")
    end

    socket =
      socket
      |> assign(:timeframe, :weekly) # Default view
      |> assign(:developer_stats, fetch_team_performance(socket.assigns.tenant, :weekly))

    {:ok, socket}
  end

  @impl true
  def handle_event("select_timeframe", %{"period" => period}, socket) do
    timeframe = String.to_existing_atom(period)
    updated_stats = fetch_team_performance(socket.assigns.tenant, timeframe)

    {:noreply, assign(socket, timeframe: timeframe, developer_stats: updated_stats)}
  end

  @impl true
  def handle_event("grant_reward", %{"dev_id" => dev_id, "reward_type" => reward_type}, socket) do
    # Logic to dispatch corporate loot crate or bonus payout
    CodeMantra.Gamification.GrantReward.exec(dev_id, reward_type, tenant: socket.assigns.tenant)

    {:noreply, put_flash(socket, :info, "Reward granted successfully!")}
  end

  defp fetch_team_performance(_tenant_id, :daily) do
    [
      %{
        id: "usr_elixir_lead",
        name: "Jason Clark",
        handle: "jason_c",
        flow_multiplier: "2.8x (Overclocked)",
        focus_hours: "6.2 hrs",
        chambers_cleared: 3,
        tech_debt_cleared: "250 pts",
        mvp_score: 95
      }
    ]
  end

  defp fetch_team_performance(_tenant_id, :weekly) do
    [
      %{
        id: "usr_elixir_lead",
        name: "Jason Clark",
        handle: "jason_c",
        flow_multiplier: "2.4x Avg",
        focus_hours: "28.5 hrs",
        chambers_cleared: 18,
        tech_debt_cleared: "1,420 pts",
        mvp_score: 98
      }
    ]
  end

  defp fetch_team_performance(_tenant_id, :monthly) do
    [
      %{
        id: "usr_elixir_lead",
        name: "Jason Clark",
        handle: "jason_c",
        flow_multiplier: "2.1x Avg",
        focus_hours: "112.0 hrs",
        chambers_cleared: 74,
        tech_debt_cleared: "5,800 pts",
        mvp_score: 99
      }
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
        <div class="p-6 bg-slate-950 text-slate-100 font-mono rounded-xl border border-slate-800">
          <!-- Dashboard Header -->
          <div class="flex flex-col md:flex-row justify-between items-start md:items-center mb-6 gap-4 border-b border-slate-800 pb-4">
            <div>
              <h1 class="text-2xl font-bold text-cyan-400 flex items-center gap-2">
                <span>📊</span> Guild Overseer: Developer Performance Matrix
              </h1>
              <p class="text-xs text-slate-400 mt-1">Tenant-Isolated Enterprise Manager Telemetry</p>
            </div>

            <!-- Timeframe Toggle Tabs -->
            <div class="flex bg-slate-900 p-1 rounded-lg border border-slate-800 text-xs">
              <button
                phx-click="select_timeframe"
                phx-value-period="daily"
                class={["px-3 py-1 rounded transition font-bold", @timeframe == :daily && "bg-cyan-500 text-slate-950" || "text-slate-400 hover:text-white"]}>
                Today (24h)
              </button>
              <button
                phx-click="select_timeframe"
                phx-value-period="weekly"
                class={["px-3 py-1 rounded transition font-bold", @timeframe == :weekly && "bg-cyan-500 text-slate-950" || "text-slate-400 hover:text-white"]}>
                This Week
              </button>
              <button
                phx-click="select_timeframe"
                phx-value-period="monthly"
                class={["px-3 py-1 rounded transition font-bold", @timeframe == :monthly && "bg-cyan-500 text-slate-950" || "text-slate-400 hover:text-white"]}>
                This Month
              </button>
            </div>
          </div>

          <!-- Developer Performance Table -->
          <div class="overflow-x-auto">
            <table class="w-full text-left text-sm text-slate-300">
              <thead class="bg-slate-900 text-xs text-slate-400 uppercase border-b border-slate-800">
                <tr>
                  <th class="p-3">Developer</th>
                  <th class="p-3">Flow Cadence</th>
                  <th class="p-3">Focus Hours</th>
                  <th class="p-3">PR Chambers</th>
                  <th class="p-3">Tech Debt Resolved</th>
                  <th class="p-3">MVP Rating</th>
                  <th class="p-3 text-right">Incentives</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-800/60">
                <%= for dev <- @developer_stats do %>
                  <tr class="hover:bg-slate-900/50 transition">
                    <td class="p-3 font-semibold text-white flex items-center gap-2">
                      <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
                      <%= dev.name %> <span class="text-xs text-slate-500">(@<%= dev.handle %>)</span>
                    </td>
                    <td class="p-3 text-amber-400 font-bold"><%= dev.flow_multiplier %></td>
                    <td class="p-3 text-slate-300"><%= dev.focus_hours %></td>
                    <td class="p-3"><%= dev.chambers_cleared %> PRs</td>
                    <td class="p-3 text-cyan-300"><%= dev.tech_debt_cleared %></td>
                    <td class="p-3">
                      <span class="px-2 py-0.5 rounded text-xs font-bold bg-indigo-950 text-indigo-300 border border-indigo-800">
                        <%= dev.mvp_score %> / 100
                      </span>
                    </td>
                    <td class="p-3 text-right">
                      <button
                        phx-click="grant_reward"
                        phx-value-dev_id={dev.id}
                        phx-value-reward_type="corporate_loot_box"
                        class="bg-amber-600 hover:bg-amber-500 text-slate-950 font-bold px-3 py-1 rounded text-xs transition">
                        🎁 Reward Hard Coder
                      </button>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
  """
  end
end