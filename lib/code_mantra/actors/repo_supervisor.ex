defmodule CodeMantra.RepoSupervisor do
  @moduledoc """
  Top-Level Repository Supervisor.
  Manages dynamic child worker supervision across active repository sandboxes,
  compilation daemons, and isolated IDE gateway instances.
  """
  use DynamicSupervisor
  require Logger

  # --- Client API ---
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_repo_worker(repo_id, repo_config \\ %{}) do
    spec = {CodeMantra.Workers.RepoSandbox, {repo_id, repo_config}}

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} ->
        Logger.info("[REPO_SUPERVISOR] Successfully spawned worker for repository #{repo_id} at #{inspect(pid)}")
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.warning("[REPO_SUPERVISOR] Repo worker for #{repo_id} is already running at #{inspect(pid)}")
        {:ok, pid}

      {:error, reason} = error ->
        Logger.error("[REPO_SUPERVISOR] Failed to spawn worker for repo #{repo_id}: #{inspect(reason)}")
        error
    end
  end

  def terminate_repo_worker(pid) when is_pid(pid) do
    case DynamicSupervisor.terminate_child(__MODULE__, pid) do
      :ok ->
        Logger.info("[REPO_SUPERVISOR] Successfully terminated repo worker #{inspect(pid)}")
        :ok

      {:error, :not_found} ->
        Logger.warning("[REPO_SUPERVISOR] Attempted to terminate non-existent repo worker #{inspect(pid)}")
        {:error, :not_found}
    end
  end

  def terminate_repo_worker(repo_id) when is_binary(repo_id) or is_atom(repo_id) do
    # Find and terminate by inspecting children if a string/atom ID is passed
    case find_worker_pid(repo_id) do
      {:ok, pid} -> terminate_repo_worker(pid)
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  # --- Supervisor Callbacks ---
  @impl true
  def init(_init_arg) do
    Logger.info("[REPO_SUPERVISOR] Initialized DynamicSupervisor for repository sandboxes.")
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # --- Internal Helpers ---
  defp find_worker_pid(repo_id) do
    children = DynamicSupervisor.which_children(__MODULE__)

    found = Enum.find(children, fn {_, pid, _, _} ->
      # Inspect process state or match metadata if applicable
      case Process.info(pid, :dictionary) do
        {:dictionary, dict} -> Keyword.get(dict, :repo_id) == repo_id
        _ -> false
      end
    end)

    case found do
      {_, pid, _, _} when is_pid(pid) -> {:ok, pid}
      _ -> {:error, :not_found}
    end
  end
end