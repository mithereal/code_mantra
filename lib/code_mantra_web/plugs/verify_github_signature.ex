defmodule CodeMantraWeb.Plugs.VerifyGithubSignature do
  @moduledoc """
  Plug that intercepts incoming GitHub Webhook requests, reads the raw body,
  and performs constant-time cryptographic verification against the X-Hub-Signature-256 header.
  """

  import Plug.Conn
  @behaviour Plug

  @signature_header "x-hub-signature-256"

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    secret = System.get_env("GITHUB_WEBHOOK_SECRET") || raise "GITHUB_WEBHOOK_SECRET is missing"

    with [signature] <- get_req_header(conn, @signature_header),
         {:ok, body, conn} <- read_raw_body(conn),
         true <- valid_signature?(secret, body, signature) do
      conn
    else
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          401,
          Jason.encode!(%{error: "Unauthorized: Invalid or missing webhook signature"})
        )
        |> halt()
    end
  end

  @doc """
  Reads the raw unparsed request body so the HMAC hash matches
  byte-for-byte what GitHub transmitted.
  """
  defp read_raw_body(conn) do
    case Plug.Conn.read_body(conn) do
      {:ok, body, conn} -> {:ok, body, conn}
      # Handle chunked requests if necessary
      {:more, _, conn} -> {:ok, "", conn}
      {:error, _} -> {:error, :body_read_failed}
    end
  end

  @doc """
  Computes the HMAC-SHA256 hash of the payload using the secret
  and compares it safely against the header signature using constant-time comparison.
  """
  defp valid_signature?(secret, body, "sha256=" <> provided_sig) do
    computed_sig =
      :crypto.mac(:hmac, :sha256, secret, body)
      |> Base.encode16(case: :lower)

    # Prevent timing attacks using Plug.Crypto.secure_compare/2
    Plug.Crypto.secure_compare(computed_sig, provided_sig)
  end

  defp valid_signature?(_secret, _body, _invalid_format), do: false
end
