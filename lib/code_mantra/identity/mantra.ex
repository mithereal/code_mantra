defmodule CodeMantra.Identity.Mantra do
  @moduledoc """
  Handles encoding developer state into signed Mantra strings
  and parsing incoming Mantras into verified Profile Identity Snapshots.
  """

  @secret_key System.get_env("MANTRA_SIGNING_SECRET") || "fallback_mantra_secret"

  @doc "Encodes developer telemetry and equipment into a signed Mantra string"
  def generate_mantra(dev_profile) do
    payload = %{
      usr: dev_profile.id,
      rank: dev_profile.main_language_rank,
      editor: dev_profile.editor_type,
      flow: dev_profile.flow_multiplier,
      mvp: dev_profile.mvp_score,
      familiar: dev_profile.familiar_type,
      ts: DateTime.utc_now() |> DateTime.to_unix()
    }

    encoded_payload =
      payload
      |> Jason.encode!()
      |> Base.url_encode64(padding: false)

    signature = compute_signature(encoded_payload)

    "CM-v1.#{dev_profile.tenant_id}.#{encoded_payload}.#{signature}"
  end

  @doc "Parses and verifies an incoming Mantra string to render the Profile Snapshot"
  def parse_mantra("CM-v1." <> rest) do
    case String.split(rest, ".") do
      [tenant_id, payload_b64, signature] ->
        if Plug.Crypto.secure_compare(compute_signature(payload_b64), signature) do
          case Base.url_decode64(payload_b64, padding: false) do
            {:ok, json_str} ->
              {:ok, data} = Jason.decode(json_str)
              {:ok, build_snapshot_struct(tenant_id, data)}

            _ ->
              {:error, :corrupted_payload}
          end
        else
          {:error, :invalid_signature}
        end

      _ ->
        {:error, :malformed_mantra}
    end
  end

  def parse_mantra(_), do: {:error, :invalid_mantra_prefix}

  defp compute_signature(payload) do
    :crypto.mac(:hmac, :sha256, @secret_key, payload)
    |> Base.encode16(case: :lower)
  end

  defp build_snapshot_struct(tenant_id, data) do
    %{
      tenant: tenant_id,
      user_id: data["usr"],
      language_rank: data["rank"],
      editor: String.to_atom(data["editor"]),
      flow_multiplier: data["flow"],
      mvp_score: data["mvp"],
      familiar: String.to_atom(data["familiar"]),
      generated_at: DateTime.from_unix!(data["ts"])
    }
  end
end
