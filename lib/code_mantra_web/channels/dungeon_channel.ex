defmodule CodeMantraWeb.DungeonChannel do
  @moduledoc """
  Multiplayer Repo Dungeon Channel.
  Tracks multi-developer commits, git fractures, boss encounters,
  and alliance raid strikes against The Monolith King.
  """
  use CodeMantraWeb, :channel

  @impl true
  def join("repo_dungeon:" <> repo_id, _payload, socket) do
    send(self(), :after_join)
    {:ok, assign(socket, :repo_id, repo_id)}
  end

  @impl true
  def handle_info(:after_join, socket) do
    push(socket, "presence_state", %{status: "connected_to_dungeon"})
    {:noreply, socket}
  end

  @impl true
  def handle_in("strike_monolith", %{"damage" => damage}, socket) do
    repo_id = socket.assigns.repo_id
    user_id = socket.assigns.user_id

    # Route strike against The Monolith King world boss
    case CodeMantra.Actors.DungeonOrchestrator.strike_boss(repo_id, user_id, damage) do
      {:ok, updated_hp, status} ->
        broadcast!(socket, "boss_hp_updated", %{
          current_hp: updated_hp,
          status: status,
          striker: user_id
        })

        {:reply, {:ok, %{hp: updated_hp, status: status}}, socket}

      error ->
        {:reply, {:error, inspect(error)}, socket}
    end
  end

  @impl true
  def handle_in("deploy_shield", %{"target" => target_id, "class" => class_type}, socket) do
    repo_id = socket.assigns.repo_id
    defender_id = socket.assigns.user_id

    case CodeMantra.Actors.DungeonOrchestrator.deploy_class_shield(
           repo_id,
           defender_id,
           target_id,
           String.to_atom(class_type)
         ) do
      {:ok, shield_type} ->
        {:reply, {:ok, %{shield: shield_type}}, socket}

      _ ->
        {:reply, {:error, :shield_failed}, socket}
    end
  end
end
