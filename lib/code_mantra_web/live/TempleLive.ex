defmodule CodeMantraWeb.TempleLive do
  use CodeMantraWeb, :live_view

  alias CodeMantra.Identity.Guru

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, mantra_input: "", snapshot: nil, error: nil)}
  end

  @impl true
  def handle_event("submit_mantra", %{"mantra" => code}, socket) do
    case Guru.verify_and_consecrate(code) do
      {:ok, tenant, data} ->
        {:noreply, assign(socket, snapshot: data, tenant: tenant, error: nil)}

      {:error, reason} ->
        {:noreply, assign(socket, error: "Temple Rejection: #{reason}", snapshot: nil)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto p-6 bg-slate-900 text-slate-100 rounded-xl border border-amber-500/30 shadow-2xl">
      <h2 class="text-2xl font-mono text-amber-400 mb-2">🏛️ The Temple of the Guru</h2>
      <p class="text-sm text-slate-400 mb-6">
        Present your sacred mantra to consecrate your identity snapshot.
      </p>

      <form phx-submit="submit_mantra" class="flex gap-2 mb-6">
        <input
          type="text"
          name="mantra"
          value={@mantra_input}
          placeholder="MANT-AZ-TUC-..."
          class="flex-1 bg-slate-950 border border-slate-700 rounded px-3 py-2 font-mono text-sm text-amber-300 focus:outline-none focus:border-amber-500"
        />
        <button
          type="submit"
          class="bg-amber-600 hover:bg-amber-500 font-semibold px-4 py-2 rounded text-slate-950 transition-colors"
        >
          Consecrate
        </button>
      </form>

      <%= if @error do %>
        <div class="p-3 bg-red-950/50 border border-red-500/50 text-red-300 rounded text-sm font-mono mb-4">
          {@error}
        </div>
      <% end %>

      <%= if @snapshot do %>
        <div class="p-4 bg-slate-950 rounded-lg border border-amber-500/50 space-y-3 font-mono">
          <div class="flex justify-between items-center text-xs text-amber-400 border-b border-slate-800 pb-2">
            <span>REALM TENANT: {@tenant}</span>
            <span>[VERIFIED]</span>
          </div>
          <div class="grid grid-cols-2 gap-2 text-sm">
            <div><span class="text-slate-500">User:</span> {@snapshot.usr}</div>
            <div><span class="text-slate-500">Rank:</span> #{@snapshot.rank}</div>
            <div><span class="text-slate-500">Editor:</span> #{@snapshot.editor}</div>
            <div><span class="text-slate-500">Flow:</span> #{@snapshot.flow}x</div>
            <div><span class="text-slate-500">MVP Score:</span> {@snapshot.mvp}</div>
            <div>
              <span class="text-slate-500">Familiar:</span>
              #{@snapshot.familiar} (Lvl {@snapshot.fam_lvl})
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
