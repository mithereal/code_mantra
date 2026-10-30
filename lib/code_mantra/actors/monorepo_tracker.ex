defmodule CodeMantra.Actors.MonorepoTracker do
  @moduledoc """
  Background telemetry monitoring agent for corporate Monorepo dungeon layers.
  Listens for git fractures, branch lockouts, and shared repository bounties.
  """
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    Phoenix.PubSub.subscribe(CodeMantra.PubSub, "monorepo_threat_feed")
    Logger.info("📡 [MONOREPO_TRACKER] Initialized monitoring agent for corporate Monorepo layers.")
    {:ok, state}
  end

  @impl true
  def handle_info({:git_fracture_detected, details}, state) do
    Logger.error("🚨 [THREAT ALERT]: Teammate push threw validation errors! #{details.repo} -> #{details.branch}")
    broadcast_alert(:git_fracture, details)
    {:noreply, state}
  end

  @impl true
  def handle_info({:merge_lock_event, details}, state) do
    Logger.error("🔒 [MERGE LOCK]: Global Merge Conflict locked down protected branch #{details.branch}!")
    broadcast_alert(:merge_lock, details)
    {:noreply, state}
  end

  defp broadcast_alert(type, details) do
    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "world_crawl_feed",
      {:monorepo_alert, %{type: type, payload: details}}
    )
  end
end