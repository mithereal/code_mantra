defmodule CodeMantraWeb.TelemetryController do
  use CodeMantraWeb, :controller
  alias CodeMantra.Actors.ProgressionBalancer

  def receive_batch(conn, %{"user_id" => user_id, "batches" => batches}) when is_list(batches) do
    # Forward each sliding window batch to ProgressionBalancer (Actor 3)
    Enum.each(batches, fn batch ->
      ProgressionBalancer.process_telemetry(user_id, batch)
    end)

    conn
    |> put_status(:accepted)
    |> json(%{status: "processed", batch_count: length(batches)})
  end

  def receive_batch(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid telemetry payload structure"})
  end
end