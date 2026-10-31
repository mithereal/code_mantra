defmodule CodeMantraWeb.TelemetrySocket do
  use Phoenix.Socket

  alias CodeMantra.Identity.Guru

  channel "telemetry:*", CodeMantraWeb.TelemetryChannel

  @impl true
  def connect(%{"mantra" => mantra_token}, socket, _connect_info) do
    case Guru.verify_mantra(mantra_token) do
      {:ok, payload} ->
        socket =
          socket
          |> assign(:user_id, payload.usr)
          |> assign(:tenant_id, Map.get(payload, :tenant_id, "default_tenant"))
          |> assign(:guru_payload, payload)

        {:ok, socket}

      {:error, _reason} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "telemetry_socket:#{socket.assigns.user_id}"
end
