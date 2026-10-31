defmodule CodeMantra.Rewards.PayoutHandler do
  @moduledoc """
  Dispatches real-world payouts to corporate HR/Payroll APIs when a loot box is opened.
  """

  alias CodeMantra.Rewards.CorporateLootBox

  @doc "Processes an opened loot box and notifies HR/Payroll channels"
  def process_unboxed_reward(loot_box_id, tenant_id) do
    with {:ok, box} <- Ash.get(CorporateLootBox, loot_box_id, tenant: tenant_id) do
      # 1. Dispatch Webhook to Payroll/HR platform (Gusto / Rippling)
      notify_payroll_system(box)

      # 2. Broadcast celebration on the company's internal LiveView wallboard
      broadcast_reward_announcement(box)

      {:ok, box}
    end
  end

  defp notify_payroll_system(box) do
    payload = %{
      employee_id: box.recipient_id,
      reward_type: box.reward_type,
      reward_value: box.reward_value,
      granted_by: box.granted_by_id,
      timestamp: box.opened_at
    }

    # Example: POST request to corporate webhook / HR queue
    # HTTPoison.post("https://api.company.com/hr/payroll_adjustments", Jason.encode!(payload))
    IO.inspect(payload, label: "HR Payroll Adjustment Dispatched")
  end

  defp broadcast_reward_announcement(box) do
    reward_text = format_reward_text(box.reward_type, box.reward_value)

    Phoenix.PubSub.broadcast(
      CodeMantra.PubSub,
      "org_metrics:#{box.organization_id}",
      {:loot_box_opened,
       %{
         recipient_id: box.recipient_id,
         reward_text: reward_text,
         tier: box.tier
       }}
    )
  end

  defp format_reward_text(:pay_raise_percent, val), do: "🎉 PERMANENT #{val}% PAY RAISE UNLOCKED!"
  defp format_reward_text(:gift_card_usd, val), do: "🎁 $#{val} Visa Gift Card Claimed!"
  defp format_reward_text(:pto_hours, val), do: "🏖️ #{div(val, 8)} Day(s) Paid Time Off Granted!"
  defp format_reward_text(:tech_stipend_usd, val), do: "🖥️ $#{val} Hardware/Gear Stipend Unlocked!"
end
