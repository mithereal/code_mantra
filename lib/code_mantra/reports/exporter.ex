defmodule CodeMantra.Reports.Exporter do
  @moduledoc """
  Generates executive performance reports for corporate managers,
  exporting monthly and weekly developer telemetry into downloadable files.
  """

  alias CodeMantra.Telemetry.DeveloperMetrics

  @doc "Generates an executive summary payload for a specific time horizon"
  def generate_report_payload(tenant_id, timeframe) do
    metrics = DeveloperMetrics.get_tenant_summary(tenant_id, timeframe)

    %{
      tenant_id: tenant_id,
      generated_at: DateTime.utc_now(),
      timeframe: timeframe,
      total_developers: length(metrics),
      top_mvp: Enum.max_by(metrics, & &1.mvp_score),
      developers: metrics
    }
  end

  @doc "Formats telemetry data into an structured CSV/Spreadsheet export"
  def export_to_csv(tenant_id, timeframe) do
    payload = generate_report_payload(tenant_id, timeframe)

    headers =
      "Developer,Handle,Focus Hours,Flow Avg,PR Chambers Cleared,Tech Debt Points,MVP Score\n"

    rows =
      Enum.map_join(payload.developers, "\n", fn dev ->
        "\"#{dev.name}\",\"#{dev.handle}\",#{dev.focus_hours},#{dev.flow_avg},#{dev.prs_cleared},#{dev.tech_debt_points},#{dev.mvp_score}"
      end)

    {:ok, headers <> rows}
  end
end
