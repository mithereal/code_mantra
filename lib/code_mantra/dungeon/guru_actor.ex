defmodule CodeMantra.Dungeon.GuruActor do
  use GenServer, restart: :transient

  @moduledoc """
  Manages NPC dialogue, refactoring quest generation, and
  error translation for developers interacting with The Guru in-game.
  """

  def start_link(realm_id) do
    GenServer.start_link(__MODULE__, realm_id, name: via_tuple(realm_id))
  end

  def consult_guru(realm_id, developer_id, query_type, payload) do
    GenServer.call(via_tuple(realm_id), {:consult, developer_id, query_type, payload})
  end

  @impl true
  def init(realm_id) do
    {:ok, %{realm_id: realm_id, wisdom_cache: %{}}}
  end

  @impl true
  def handle_call({:consult, _developer_id, :translate_error, %{stacktrace: trace}}, _from, state) do
    translated_wisdom = parse_and_gamify_stacktrace(trace)
    {:reply, {:ok, translated_wisdom}, state}
  end

  def handle_call({:consult, _developer_id, :request_quest, _}, _from, state) do
    quest = %{
      title: "The Cleansing of the Monolithic Function",
      objective: "Reduce cyclomatic complexity in `data_processor.ex` below 10.",
      reward_xp: 750,
      reward_gold: 300
    }

    {:reply, {:ok, quest}, state}
  end

  defp parse_and_gamify_stacktrace(_trace) do
    %{
      npc_dialogue:
        "Beware! A dark barrier of unhandled exceptions blocks your path. Apply pattern matching to banish the error.",
      suggested_fix: "Match explicitly on `{:ok, result}` instead of relying on wildcard clauses."
    }
  end

  pvt = fn id -> {:via, Registry, {CodeMantra.RealmRegistry, "guru:#{id}"}} end
  defp via_tuple(realm_id), do: pvt.(realm_id)
end
