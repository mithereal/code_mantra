defmodule CodeMantra.Identity.Guru do
  @moduledoc """
  The Guru: Resides in the temple to encode rich developer telemetry
  into dash-separated retro password blocks, secured with an HMAC-SHA256 signature.
  """

  @secret_key System.get_env("MANTRA_SIGNING_SECRET") || "king_guru_secret_2026"

  @doc """
  Takes full actor state, serializes it, and formats it into a dash-separated
  Faxanadu-style mantra token: MANT-TENANT-CHUNK1-CHUNK2-...-CHECKSUM
  """
  def bless_and_sign(tenant_id, state_map) do
    payload_b64 =
      state_map
      |> Jason.encode!()
      |> Base.url_encode64(padding: false)

    checksum = compute_checksum(payload_b64)

    chunks =
      payload_b64
      |> String.to_charlist()
      |> Enum.chunk_every(5)
      |> Enum.map(&List.to_string/1)

    parts = ["MANT", tenant_id] ++ chunks ++ [checksum]
    Enum.join(parts, "-")
  end

  @doc """
  Verifies the checksum and unpacks the dash-separated mantra back into
  the complete developer state snapshot.
  """
  def verify_and_consecrate(mantra_str) do
    clean_code = mantra_str |> String.trim() |> String.upcase()
    parts = String.split(clean_code, "-")

    case parts do
      ["MANT", tenant_id | rest] when length(rest) >= 2 ->
        {chunk_list, [provided_checksum]} = Enum.split(rest, -1)
        payload_b64 = Enum.join(chunk_list, "")

        expected_checksum = compute_checksum(payload_b64)

        if Plug.Crypto.secure_compare(expected_checksum, provided_checksum) do
          case Base.url_decode64(payload_b64, padding: false) do
            {:ok, json_str} ->
              data = Jason.decode!(json_str)
              {:ok, tenant_id, symbolize_keys(data)}

            _ ->
              {:error, :corrupted_payload_encoding}
          end
        else
          {:error, :unholy_mantra_tampered}
        end

      _ ->
        {:error, :malformed_mantra_format}
    end
  end

  defp compute_checksum(payload_b64) do
    :crypto.mac(:hmac, :sha256, @secret_key, payload_b64)
    |> Base.encode16(case: :upper)
    |> String.slice(0, 6)
  end

  defp symbolize_keys(map) do
    Map.new(map, fn {k, v} -> {String.to_existing_atom(k), v} end)
  end
end
