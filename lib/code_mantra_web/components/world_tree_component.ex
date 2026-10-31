defmodule CodeMantraWeb.Components.WorldTreeComponent do
  @moduledoc """
  Renders the World Tree branch hierarchy and GitHub Issue dungeon nodes.
  """
  use CodeMantraWeb, :html

  def render(assigns) do
    ~H"""
    <div class="bg-slate-900 border border-slate-800 rounded-xl p-6 shadow-2xl font-mono">
      <div class="flex justify-between items-center mb-4 border-b border-slate-800 pb-3">
        <div>
          <h2 class="text-lg font-bold text-emerald-400 flex items-center gap-2">
            <span>🌳 THE WORLD TREE</span>
          </h2>
          <p class="text-xs text-slate-400">Project Realm: {@realm_id}</p>
        </div>
        <span class="text-xs bg-emerald-950 text-emerald-400 border border-emerald-800 px-3 py-1 rounded-full font-bold">
          Canopy Level: {@world_level}
        </span>
      </div>
      
    <!-- Tree Branch Dungeon Grid -->
      <div class="space-y-4">
        <%= for {branch_name, dungeon} <- @branches do %>
          <div class="bg-slate-950 border border-slate-800 rounded-lg p-4 space-y-3">
            <div class="flex justify-between items-center">
              <span class="text-sm font-bold text-amber-300">🌿 Branch: {branch_name}</span>
              <span class="text-xs text-slate-500">
                {map_size(dungeon.dungeon_rooms)} Issue Chambers
              </span>
            </div>
            
    <!-- Issue Rooms/Nodes -->
            <div class="grid grid-cols-2 md:grid-cols-4 gap-2">
              <%= for {issue_id, room_node} <- dungeon.dungeon_rooms do %>
                <div class={"p-2 rounded border text-xs flex items-center justify-between #{if room_node.cleared, do: "bg-emerald-950/40 border-emerald-800 text-emerald-300", else: "bg-red-950/40 border-red-900 text-red-300"}"}>
                  <div class="truncate">
                    <span class="font-bold">#{issue_id}</span>
                    <p class="truncate text-[10px] text-slate-400">{room_node.title}</p>
                  </div>
                  <span>{if room_node.cleared, do: "⚔️ CLEARED", else: "👾 BOSS"}</span>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
