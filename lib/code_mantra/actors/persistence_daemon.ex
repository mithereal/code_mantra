defmodule CodeMantra.Actors.PersistenceDaemon do
  @moduledoc """
  Actor 4: PERSISTENCE DAEMON.
  Buffers in-memory progress deltas (XP, Gold, and Monolith King strikes) and flushes
  runic state checkpoints down to PostgreSQL via Ash resources at 30-second intervals.
  Also archives elite procedurally generated ranks and titles for team inheritance.
  """
  use GenServer
  require Logger

  alias CodeMantra.Gamification
  alias CodeMantra.Domain.{PlayerProfile, SharedRank}

  # --- Client API ---
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{pending_deltas: %{}}, name: __MODULE__)
  end

  def queue_delta(user_id, delta) when is_map(delta) do
    GenServer.cast(__MODULE__, {:buffer_delta, user_id, delta})
  end

  def archive_rank(user_id, rank_payload) do
    GenServer.cast(__MODULE__, {:archive_rank, user_id, rank_payload})
  end

  def force_flush do
    GenServer.call(__MODULE__, :flush_now)
  end

  # --- Server Callbacks ---
  @impl true
  def init(state) do
    :timer.send_interval(30_000, :flush_to_db)
    Logger.info("[PERSISTENCE_DAEMON] Initialized and listening for state checkpoints & rank archives.")
    {:ok, state}
  end

  @impl true
  def handle_cast({:buffer_delta, user_id, delta}, state) do
    current = Map.get(state.pending_deltas, user_id, %{xp: 0, gold: 0})

    updated_delta = %{
      xp: current.xp + Map.get(delta, :xp, 0),
      gold: current.gold + Map.get(delta, :gold, 0)
    }

    new_deltas = Map.put(state.pending_deltas, user_id, updated_delta)
    {:noreply, %{state | pending_deltas: new_deltas}}
  end

  @impl true
  def handle_cast({:archive_rank, user_id, payload}, state) do
    tier = payload["tier_badge"] || "D"

    if tier in ["S", "S+", "SS", "SS+", "SSS", "SSS+", "X", "X+", "OMEGA"] do
      SharedRank
      |> Ash.Changeset.for_create(:archive, %{
        title: payload["royal_title"],
        rank_name: payload["rank_name"],
        tier_badge: tier,
        paradigm: payload["paradigm"] || :polyglot_generic,
        creator_id: to_string(user_id),
        realm_id: Map.get(payload, "realm_id", "REALM-4aef81")
      })
      |> Ash.create(domain: Gamification)

      Logger.info("[PERSISTENCE_DAEMON] 🏛️ Archived elite rank '#{payload["rank_name"]}' (#{tier}) by User #{user_id} for team inheritance.")
    end

    {:noreply, state}
  end

  @impl true
  def handle_call(:flush_now, _from, state) do
    flush_pending(state.pending_deltas)
    {:reply, :ok, %{state | pending_deltas: %{}}}
  end

  @impl true
  def handle_info(:flush_to_db, state) do
    flush_pending(state.pending_deltas)
    {:noreply, %{state | pending_deltas: %{}}}
  end

  # --- Internal Flush Implementation ---
  defp flush_pending(deltas) when map_size(deltas) == 0, do: :ok
  defp flush_pending(deltas) do
    Logger.info("[PERSISTENCE_DAEMON] Flushing #{map_size(deltas)} user state checkpoints to PostgreSQL...")

    Enum.each(deltas, fn {user_id, delta} ->
      case Ash.get(PlayerProfile, user_id) do
        {:ok, profile} when not is_nil(profile) ->
          profile
          |> Ash.Changeset.for_update(:award_telemetry_loot, %{
            xp_delta: delta.xp,
            gold_delta: delta.gold
          })
          |> Ash.update!(domain: Gamification)

          Logger.debug("[PERSISTENCE_DAEMON] Successfully persisted #{delta.xp} XP and #{delta.gold} Gold for User #{user_id}")

        _ ->
          Logger.warning("[PERSISTENCE_DAEMON] Failed to locate PlayerProfile for ID #{user_id} during checkpoint flush.")
      end
    end)
  end
end