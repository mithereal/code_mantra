defmodule CodeMantraWeb.GithubWebhookController do
  use CodeMantraWeb, :controller

  alias CodeMantra.Dungeon.RealmActor

  @doc "Processes inbound GitHub Webhook events and routes them to the Realm GenServer"
  def handle_webhook(conn, %{"action" => "closed", "pull_request" => %{"merged" => true} = pr}) do
    repo_name = pr["base"]["repo"]["full_name"]
    author_github_handle = pr["user"]["login"]

    pr_stats = %{
      additions: pr["additions"],
      deletions: pr["deletions"],
      changed_files: pr["changed_files"]
    }

    # Signal the repository's Realm GenServer that a boss has been slain
    RealmActor.process_pr_merge(repo_name, author_github_handle, pr_stats)

    conn
    |> put_status(:ok)
    |> json(%{status: "PR Merge Event Ingested"})
  end

  def handle_webhook(conn, _params) do
    # Fallback for unhandled webhook events
    conn |> put_status(:ok) |> json(%{status: "Event Ignored"})
  end
end
