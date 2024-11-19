defmodule GoWeb.GameBoardLive do
  use GoWeb, :live_view

  alias Go.GameBoard

  def render(assigns) do
    ~H"""
    <div class="captures">
      <div>
        <%= for _ <- 1..@game_board.captures.black, @game_board.captures.black > 0 do %>
          <span class="black"></span>
        <% end %>
      </div>
      <div>
        <%= for _ <- 1..@game_board.captures.white, @game_board.captures.white > 0 do %>
          <span class="white"></span>
        <% end %>
      </div>
    </div>

    <div class="board">
      <%= for {value, index} <- Enum.with_index(@game_board.positions) do %>
        <%= if Go.GameBoard.legality_move?(@game_board, index) do %>
          <button phx-click="place" phx-value={index} class={value}></button>
        <% else %>
          <button class={value} disabled="disabled"></button>
        <% end %>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    game_board = %GameBoard{}
    {:ok, socket |> assign(game_board: game_board)}
  end
end
