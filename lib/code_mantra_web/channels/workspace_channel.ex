defmodule CodeMantraWeb.WorkspaceChannel do
  @moduledoc """
  Handles live editor telemetry ingestion, mantra parsing, combat events,
  and downstream actor routing for a specific developer workspace.
  """
  use CodeMantraWeb, :channel
  alias CodeMantra.Engine.MantraParser.Incantation

  @impl true
  def join("developer_workspace:" <> user_id, _payload, socket) do
    {:ok, assign(socket, :user_id, user_id)}
  end

  @impl true
  def handle_in("telemetry_batch", payload, socket) do
    user_id = socket.assigns.user_id

    # 1. Scan code buffer for tactical @mantra annotations
    if content = payload["buffer_content"] do
      Incantation.scan_and_cast(content, user_id)
    end

    # 2. Forward telemetry to Actor 2 (EvaluationDaemon) for polyglot/rank synthesis
    CodeMantra.Actors.EvaluationDaemon.evaluate_ast(user_id, payload)

    {:reply, :ok, socket}
  end

  @impl true
  def handle_in("execute_sigkill", %{"encounter_id" => encounter_id}, socket) do
    user_id = socket.assigns.user_id

    case CodeMantra.Actors.BossEncounterEngine.execute_sigkill(user_id, encounter_id) do
      {:ok, :decapitated} -> {:reply, {:ok, %{status: :cleared}}, socket}
      error -> {:reply, {:error, inspect(error)}, socket}
    end
  end
end