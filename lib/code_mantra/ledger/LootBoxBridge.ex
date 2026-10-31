defmodule CodeMantra.Ledger.LootBoxBridge do
  @moduledoc """
  Bridges in-game achievements to real-world rewards:
  Corporate payroll bonuses or Open-Source bounties.
  """

  @doc "Evaluates monthly performance and triggers the appropriate reward dispatch."
  def trigger_loot_drop(dev_profile, context \\ :corporate) do
    case context do
      :corporate ->
        dispatch_corporate_payroll_webhook(dev_profile)

      :open_source ->
        dispatch_oss_bounty(dev_profile)
    end
  end

  defp dispatch_corporate_payroll_webhook(dev) do
    if dev.mvp_score >= 95 and dev.flow_multiplier >= 2.5 do
      payload = %{
        employee_id: dev.user_id,
        bonus_tier: :legendary_loot_box,
        pto_hours_added: 8,
        stipend_adjustment: 250.00
      }

      # Req: Post to secure HR / Payroll API
      {:ok, %{status: 200, body: "Payroll bonus successfully provisioned"}}
    else
      {:ok, :standard_baseline}
    end
  end

  defp dispatch_oss_bounty(dev) do
    # Trigger GitHub Sponsor reward or Open Collective micro-grant for open-source maintainers
    {:ok, %{recipient: dev.user_id, bounty_status: :dispatched}}
  end
end
