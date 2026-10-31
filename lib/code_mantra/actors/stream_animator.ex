defmodule CodeMantra.Actors.StreamAnimator do
  @moduledoc """
  Actor 9: STREAM ANIMATOR.
  Manages real-time code streaming animations, keystroke velocity tracking,
  and high-frequency visual canvas frame synchronization across IDE clients and LiveView dashboards.
  """
  use GenServer
  require Logger

  @frame_interval 50 # 50ms animation frame tick (20 FPS)

  # --- Client API ---
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def stream_code_block(stream_id, code_snippet, target_user_id) do
    GenServer.call(__MODULE__, {:start_stream, stream_id, code_snippet, target_user_id})
  end

  def halt_stream(stream_id) do
    GenServer.cast(__MODULE__, {:halt_stream, stream_id})
  end

  def get_active_streams do
    GenServer.call(__MODULE__, :get_active_streams)
  end

  # --- Server Callbacks ---
  @impl true
  def init(_opts) do
    state = %{streams: %{}}
    Logger.info("[STREAM_ANIMATOR] Initialized and ready for high-frequency code streaming animations.")
    schedule_frame()
    {:ok, state}
  end

  @impl true
  def handle_call({:start_stream, stream_id, code_snippet, target_user_id}, _from, state) do
    chars = String.graphemes(code_snippet)
    total_chars = length(chars)

    Logger.info("✨ [STREAM_ANIMATOR] Starting stream #{stream_id} for User #{target_user_id} (#{total_chars} characters)")

    stream_data = %{
      stream_id: stream_id,
      user_id: target_user_id,
      graphemes: chars,
      total_length: total_chars,
      cursor: 0,
      status: :streaming
    }

    updated_streams = Map.put(state.streams, stream_id, stream_data)
    {:reply, {:ok, stream_id}, %{state | streams: updated_streams}}
  end

  @impl true
  def handle_call(:get_active_streams, _from, state) do
    {:reply, state.streams, state}
  end

  @impl true
  def handle_cast({:halt_stream, stream_id}, state) do
    updated_streams = Map.delete(state.streams, stream_id)
    Logger.info("🛑 [STREAM_ANIMATOR] Stream #{stream_id} halted.")
    {:noreply, %{state | streams: updated_streams}}
  end

  @impl true
  def handle_info(:frame_tick, state) do
    updated_streams =
      Enum.map(state.streams, fn {stream_id, stream} ->
        if stream.status == :streaming do
          next_cursor = min(stream.total_length, stream.cursor + 3) # Stream 3 chars per frame
          slice = Enum.take(stream.graphemes, next_cursor) |> Enum.join("")

          # Broadcast current frame chunk via Phoenix Endpoint
          CodeMantraWeb.Endpoint.broadcast!("stream:#{stream_id}", "stream_frame", %{
            stream_id: stream_id,
            content_slice: slice,
            progress: Float.round(next_cursor / stream.total_length * 100, 2),
            status: if(next_cursor >= stream.total_length, do: :completed, else: :streaming)
          })

          status = if next_cursor >= stream.total_length, do: :completed, else: :streaming
          {stream_id, %{stream | cursor: next_cursor, status: status}}
        else
          {stream_id, stream}
        end
      end)
      |> Enum.into(%{})

    # Filter out completed streams after broadcast
    active_streams = Map.reject(updated_streams, fn {_id, stream} -> stream.status == :completed end)

    schedule_frame()
    {:noreply, %{state | streams: active_streams}}
  end

  # --- Internal Helpers ---
  defp schedule_frame do
    Process.send_after(self(), :frame_tick, @frame_interval)
  end
end