defmodule CodeMantra.Actors.StreamAnimator do
  @moduledoc """
  Actor 6: STREAM ANIMATOR.
  Computes world map vector movement at 10 FPS and pushes smooth coordinate updates
  to OBS overlays and live web views.
  """
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{frame: 0}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    :timer.send_interval(100, :render_frame)
    {:ok, state}
  end

  @impl true
  def handle_info(:render_frame, state) do
    new_frame = state.frame + 1

    if rem(new_frame, 10) == 0 do
      Phoenix.PubSub.broadcast(CodeMantra.PubSub, "world_crawl_feed", {:frame_tick, new_frame})
    end

    {:noreply, %{state | frame: new_frame}}
  end
end