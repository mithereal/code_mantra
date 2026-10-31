defmodule CodeMantra.Dungeon.FamiliarActor do
  @moduledoc """
  Manages AI familiar state, level progression, hallucination checks,
  and combat synergies bound to a developer's active session.
  """
  use GenServer, restart: :transient
  require Logger

  def start_link({user_id, model_type}) do
    GenServer.start_link(__MODULE__, {user_id, model_type}, name: via_tuple(user_id))
  end

  def process_ai_suggestion(user_id, status_event) do
    ensure_started(user_id, :copilot)
    GenServer.call(via_tuple(user_id), {:suggestion_event, status_event})
  end

  # --- Callbacks ---

  @impl true
  def init({user_id, model_type}) do
    state = %{
      user_id: user_id,
      model_type: model_type,
      familiar_name: fetch_familiar_archetype(model_type),
      bond_xp: 0,
      level: 1,
      corruption_level: 0
    }

    Logger.info("🤖 [FAMILIAR] Summoned #{state.familiar_name} for user #{user_id} using #{model_type}.")
    {:ok, state}
  end

  @impl true
  def handle_call({:suggestion_event, :accepted_valid}, _from, state) do
    # Gain Bonding XP when accepting clean AI completions
    new_xp = state.bond_xp + 25
    new_level = div(new_xp, 100) + 1

    updated_state = %{
      state
    | bond_xp: new_xp,
      level: new_level,
      corruption_level: max(0, state.corruption_level - 10)
    }

    {:reply, {:ok, %{action: :combo_strike, level: new_level}}, updated_state}
  end

  @impl true
  def handle_call({:suggestion_event, :hallucination_detected}, _from, state) do
    # Trigger corruption glitch when bad AI suggestions cause syntax/linter failures
    updated_state = %{state | corruption_level: state.corruption_level + 30}

    Logger.warning("⚠️ [FAMILIAR] Hallucination detected for #{state.user_id}! Corruption spiked to #{updated_state.corruption_level}%.")

    {:reply, {:ok, %{action: :spawn_hallucination_spectre}}, updated_state}
  end

  # --- Helpers ---

  defp fetch_familiar_archetype(:copilot), do: "Automaton Sprite"
  defp fetch_familiar_archetype(:claude), do: "Rune-Bound Owl"
  defp fetch_familiar_archetype(:ollama), do: "Cybernetic Drake"
  defp fetch_familiar_archetype(_), do: "Spectral Familiar"

  defp via_tuple(user_id), do: {:via, Registry, {CodeMantra.RealmRegistry, "familiar:#{user_id}"}}

  defp ensure_started(user_id, model_type) do
    case Registry.lookup(CodeMantra.RealmRegistry, "familiar:#{user_id}") do
      [{pid, _}] ->
        pid

      [] ->
        case DynamicSupervisor.start_child(
               CodeMantra.BossSupervisor,
               {__MODULE__, {user_id, model_type}}
             ) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
        end
    end
  end
end