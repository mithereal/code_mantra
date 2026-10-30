defmodule CodeMantra.Actors.MonolithDrop do
  @moduledoc """
  Actor 6: MONOLITH DROP.
  Background world monitor that evaluates global technical debt metrics
  and awakens The Monolith King when corruption reaches critical mass.
  """
  use GenServer
  require Logger

  alias CodeMantra.Domain.MonolithKing
  alias CodeMantra.Gamification

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def summon_king(realm_id \\ "REALM-4aef81") do
    GenServer.call(__MODULE__, {:summon, realm_id})
  end

  @impl true
  def init(state) do
    :timer.send_interval(300_000, :evaluate_world_debt)
    Logger.info("[MONOLITH_DROP] World Event Daemon initialized.")
    {:ok, state}
  end

  @impl true
  def handle_call({:summon, realm_id}, _from, state) do
    case Ash.create(MonolithKing, %{realm_id: realm_id, max_hp: 250_000}, domain: Gamification, action: :awaken) do
      {:ok, king} ->
        Logger.error("👑 [WORLD EVENT]: THE MONOLITH KING HAS AWOKEN IN REALM #{realm_id}!")

        Phoenix.PubSub.broadcast(
          CodeMantra.PubSub,
          "world_crawl_feed",
          {:boss_spawned, %{realm_id: realm_id, boss_id: king.id, hp: king.max_hp}}
        )

        {:reply, {:ok, king}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info(:evaluate_world_debt, state) do
    {:noreply, state}
  end
end