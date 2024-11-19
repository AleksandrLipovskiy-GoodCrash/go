defmodule Go.Game do
  @moduledoc """
  To describe the game's history, and functions to progress the game.
  """
  use GenServer, restart: :transient

  alias Go.Game
  alias Go.GameBoard

  @timeout 600_000

  @type t :: %Game{
    history: [GameBoard.t(), ...],
    index: integer()
  }

  @doc """
  History - the *history* attribute contains a list of `Go.GameBoard` structs, where the
  first element in the list is the current state. Whenever a move is made, a
  new state is prepended to the list. The history attbibute initally holds a
  single empty State to represent the empty board

  Index - the *index* represents the current index in the history list. On
  initialization, the index is 0, as the current state is the first element in
  the history list. To jump back one turn, the index is increased to 1. The
  `state/1` function uses the index to get the state that corresponds to the
  index.
  """
  @spec __struct__() :: Game.t()
  defstruct history: [%GameBoard{}], index: 0

  def start_link(options) do
    GenServer.start_link(__MODULE__, %Game{}, options)
  end

  @impl true
  def init(game) do
    {:ok, game, @timeout}
  end

  @impl true
  def handle_call(:game, _from, game) do
    {:reply, game, game, @timeout}
  end

  @impl true
  def handle_cast({:place, position}, game) do
    {:noreply, Game.place(game, position), @timeout}
  end

  @impl true
  def handle_cast({:jump, destination}, game) do
    {:noreply, Game.jump(game, destination), @timeout}
  end

  @impl true
  def handle_info(:timeout, game) do
    {:stop, :normal, game}
  end

  @doc """
  Returns the element in the history list that corresponds to the `:index`
  attribute as the current state of the game. The index defaults to 0, so the
  first state is returned by default.

      iex> Game.state(%Game{history: [
      ...>   %Go.GameBoard{positions: [:black, nil, nil, nil], current_color: :white},
      ...>   %Go.GameBoard{positions: [nil, nil, nil, nil], current_color: :black}
      ...> ]})
      %Go.GameBoard{positions: [:black, nil, nil, nil], current_color: :white}

  If the index is set, it takes the element that corresponds to the index from
  the history list.

      iex> Game.state(%Game{
      ...>   history: [
      ...>     %Go.GameBoard{positions: [:black, nil, nil, nil], current_color: :white},
      ...>     %Go.GameBoard{positions: [nil, nil, nil, nil], current_color: :black}
      ...>   ],
      ...>   index: 1
      ...> })
      %Go.GameBoard{positions: [nil, nil, nil, nil], current_color: :black}
  """
  @spec state(Game.t()) :: GameBoard.t()
  def state(%Game{history: history, index: index}) do
    Enum.at(history, index)
  end

  @doc """
  Places a new stone on the board by prepending a new state to the history. The
  new state is created by calling `Go.GameBoard.place_on_board/2` and passing the
  current state, and the position passed to `place/2`.
  """
  @spec place(Game.t(), integer()) :: Game.t()
  def place(%Game{history: history, index: index} = game, position) do
    new_state =
      game
      |> Game.state()
      |> GameBoard.place_on_board(position)

    %{game | history: [new_state | Enum.slice(history, index..-1//1)], index: 0}
  end

  @doc """
  Jumps in history by updating the `:index` attribute.

    iex> Game.jump(%Game{index: 0}, 1)
    %Game{index: 1}
  """
  @spec jump(Game.t(), integer()) :: Game.t()
  def jump(game, destination) do
    %{game | index: destination}
  end

  @doc """
  Determines if a history index is valid for the current game.

    iex> Game.history?(%Game{}, 0)
    true

    iex> Game.history?(%Game{}, 1)
    false

    iex> Game.history?(%Game{}, -1)
    false
  """
  @spec has_history?(Game.t(), integer()) :: boolean()
  def has_history?(%Game{history: history}, index) when index >= 0 and length(history) > index do
    true
  end

  def has_history?(_game, _index), do: false

  @doc """
  Validates a potential move by checking it against the current and previous
  states.
  The move is checked against the current state using `Hayago.State.legal?/2`
  first, which returns true if the current player can place a stone their
  without it being immediately captured.
  If the stone could be placed on the passed position, the result of that move
  is checked against all states in the board's history, to prevent repeated
  board states (the ko rule).
  """
  @spec legal?(Game.t(), integer()) :: boolean()
  def legal?(game, position) do
    GameBoard.legality_move?(Game.state(game), position) and not repeated_state?(game, position)
  end

  defp repeated_state?(game, position) do
    %Game{history: [%GameBoard{positions: tentative_positions} | history]} =
      Game.place(game, position)

    Enum.any?(history, fn %GameBoard{positions: positions} ->
      positions == tentative_positions
    end)
  end
end
