defmodule GoWeb.GameBoardLive do
  use GoWeb, :live_view

  #alias Go.GameBoard

  def render(assigns) do
    ~H"""
    Welcome a board
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
