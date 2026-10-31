defmodule CodeMantraWeb.DeveloperSocket do
  @moduledoc """
  Actor 1: CLIENT_SOCKET Channel Receptor Grid.
  Ingests micro-payload JSON telemetry streams and real-time multiplayer messages
  from local editor workspace extensions.
  """
  use Phoenix.Socket

  # Channel Topography
  channel "developer_workspace:*", CodeMantraWeb.WorkspaceChannel
  channel "repo_dungeon:*", CodeMantraWeb.DungeonChannel

  @impl true
  def connect(%{"user_id" => user_id}, socket, _connect_info) do
    {:ok, assign(socket, :user_id, user_id)}
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "developer_socket:#{socket.assigns.user_id}"
end
