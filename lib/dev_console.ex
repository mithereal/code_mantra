defmodule CodeMantra.DevConsole do
  @moduledoc """
  Developer helper functions for generating, inspecting, and testing Mantras in IEx.
  """

  alias CodeMantra.Identity.{King, Priest}

  @doc "Generates a fresh signed Mantra string in IEx."
  def mantra(user_id \\ "jason_c", tenant \\ "AZ-TUC-8821") do
    mantra_str = King.issue_mantra(user_id, tenant)

    IO.puts(
      IO.ANSI.cyan() <>
        "🔮 Generated Mantra:\n" <> IO.ANSI.yellow() <> mantra_str <> IO.ANSI.reset()
    )

    mantra_str
  end

  @doc "Parses and verifies a Mantra string, outputting a formatted snapshot."
  def inspect_mantra(mantra_str) do
    case Priest.verify_and_consecrate(mantra_str) do
      {:ok, tenant_id, payload} ->
        IO.puts(IO.ANSI.green() <> "✓ MANTRA VERIFIED [Tenant: #{tenant_id}]" <> IO.ANSI.reset())
        IO.inspect(payload, pretty: true)
        {:ok, tenant_id, payload}

      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "❌ REJECTED: #{inspect(reason)}" <> IO.ANSI.reset())
        {:error, reason}
    end
  end

  @doc "Utility to simulate signature tampering on a valid Mantra."
  def tamper_mantra(mantra_str) do
    "CM-v1." <> rest = mantra_str
    [tenant, payload, _sig] = String.split(rest, ".")
    fake_sig = "a1b2c3d4e5f678901234567890abcdef1234567890abcdef1234567890abcdef"

    tampered = "CM-v1.#{tenant}.#{payload}.#{fake_sig}"
    IO.puts(IO.ANSI.magenta() <> "⚠️ Tampered Mantra Created:\n" <> IO.ANSI.reset() <> tampered)
    tampered
  end
end
