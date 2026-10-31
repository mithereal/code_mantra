defmodule CodeMantraWeb.UserSocket do
  use Phoenix.Socket

  channel "realm:*", CodeMantraWeb.RealmChannel
  channel "player:*", CodeMantraWeb.PlayerChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case CodeMantra.Accounts.verify_token(token) do
      {:ok, %{user_id: user_id, org_id: org_id, role: role}} ->
        socket =
          socket
          |> assign(:current_user_id, user_id)
          # Injects tenant into socket assigns
          |> assign(:tenant, org_id)
          |> assign(:user_role, role)

        {:ok, socket}

      {:error, _reason} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "users_socket:#{socket.assigns.current_user_id}"

  def fetch_corporate_realm(realm_id, socket) do
    CodeMantra.Realms.CorporateRealm
    |> Ash.Query.filter(realm_id == ^realm_id)
    # Enforces corporate boundary
    |> Ash.read_one(tenant: socket.assigns.tenant)
  end
end
