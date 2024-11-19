defmodule GoWeb.GameBoardLive do
  use GoWeb, :live_view

  alias Go.Game

  def render(assigns) do
    ~H"""
    <div class="captures">
      <div>
        <%= for _ <- 1..@state.captures.black, @state.captures.black > 0 do %>
          <span class="black"></span>
        <% end %>
      </div>
      <div>
        <%= for _ <- 1..@state.captures.white, @state.captures.white > 0 do %>
          <span class="white"></span>
        <% end %>
      </div>
    </div>

    <div class="board">
      <%= for {value, index} <- Enum.with_index(@state.positions) do %>
        <%= if Game.legal?(@game, index) do %>
          <button id="capture" phx-click="place" phx-value-index={index} class={value}></button>
        <% else %>
          <button id="capture" class={value} disabled="disabled"></button>
        <% end %>
      <% end %>
    </div>

    <div class="history">
      <%= if Game.has_history?(@game, @game.index + 1) do %>
        <button phx-click="jump" phx-value-history={@game.index + 1}>Undo</button>
      <% else %>
        <button disabled="disabled">Undo</button>
      <% end %>

      <%= if Game.has_history?(@game, @game.index - 1) do %>
        <button phx-click="jump" phx-value-history={@game.index - 1}>Redo</button>
      <% else %>
        <button disabled="disabled">Redo</button>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    game = %Game{}

    {:ok, assign(socket, game: game, state: Game.state(game))}
  end

  def handle_event("place", %{"index" => index}, socket) do
    new_game_state = Game.place(socket.assigns.game, String.to_integer(index))

    {:noreply, assign(socket, game: new_game_state, state: Game.state(new_game_state))}
  end

  def handle_event("jump", %{"history" => history}, socket) do
    new_game_state = Game.jump(socket.assigns.game, String.to_integer(history))

    {:noreply, assign(socket, game: new_game_state, state: Game.state(new_game_state))}
  end
end
