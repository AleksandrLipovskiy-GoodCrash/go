defmodule Go.GameBoard do
  @moduledoc """
  A struct to describe the current game board state in the game, and functions to update
  the state by placing stones and to check if a certain move is legal.
  """
  alias Go.GameBoard

  @type t :: %GameBoard{
          positions: list(),
          current_color: atom(),
          captures: %{black: integer(), white: integer()}
        }

  @doc """
  Positions - the *positions* attribute is a list of positions on the board. Initially,
  it's generated as a list of 81 `nil` values, which represent all positions on
  an empty 9 × 9 board.  When a stone is added on one of the positions, the
  value corresponding to that position gets updated to either `:black`, or
  `:white`.

  Current color - the *current_color* attribute holds the current player's color, and switches to the
  other color after every successful move. The player with the black stones
  always starts, so the initial value is `:black`.

  Captures - A stone is captured when it has no more liberties, meaning it's surrounded by
  the opponent's stones. A captured stone is removed from the board, and the
  *captures* list is incremented for the captured stone's color.
  """
  @spec __struct__() :: GameBoard.t()
  defstruct positions: Enum.map(1..81, fn _ -> nil end),
            current_color: :black,
            captures: %{black: 0, white: 0}

  @doc """
  Validates a potential move by trying it on the current state, and evaluating
  the result.

  The `legality_move?/2` function does two checks to make sure a move is legal.
  First, it checks if the position in the current state is empty, making sure there
  position a new stone is placed on is empty.

    iex> GameBoard.legality_move?(%GameBoard{positions: [nil, nil, nil, nil]}, 0)
    true
    iex> GameBoard.legality_move?(%GameBoard{positions: [:black, nil, nil, nil]}, 0)
    false

  The next check makes sure the position has liberties for the placed stone,
  meaning the stone can be placed there with at least one liberty, or part of a
  group that has at least one liberty.

  To determine if a newly placed stone will have liberties, `legality_move?/2` uses the
  `place_on_board/2` function to try placing a stone on the position that's being
  validated. Since placing a stone will remove any stones without liberties
  from the board, it checks if the stone is still there after placing it. If it
  is, the move is legal.

    iex> GameBoard.legality_move?(%GameBoard{positions: [nil, :black, :black, nil], current: :black}, 0)
    true
    iex> GameBoard.legality_move?(%GameBoard{positions: [nil, :white, :white, nil], current: :black}, 0)
    false

  Because the `place_on_board/2` function captures enemy stones first, moves on places
  that don't have any liberties but gain them by capturing the opponent's
  stones are legal as well.

    iex> GameBoard.legality_move?(
    ...>   %GameBoard{
    ...>     positions: [
    ...>       nil,    :black, :white,
    ...>       :black, :white, nil,
    ...>       :white, nil,    nil
    ...>     ],
    ...>     current: :white
    ...>   },
    ...> 0)
    true

    iex> GameBoard.legality_move?(
    ...>   %GameBoard{
    ...>     positions: [
    ...>       nil,    :black, :white,
    ...>       :black, :white, nil,
    ...>       :white, nil,    nil
    ...>     ],
    ...>     current: :black
    ...>   },
    ...> 0)
    false
  """
  @spec legality_move?(GameBoard.t(), integer()) :: boolean()
  def legality_move?(
        %GameBoard{positions: positions, current_color: current_color} = state,
        index
      ) do
    %GameBoard{positions: tentative_positions} = GameBoard.place_on_board(state, index)

    Enum.at(positions, index) == nil and Enum.at(tentative_positions, index) == current_color
  end

  @doc """
  Places a new stone on the board, captures any surrounded stones, and swaps
  the current attribute to switch the turn to the other player.

  `place_on_board/2` takes a `Go.GameBoard` struct and an *index* to place a new stone.
  When called, it replaces the state's positions list by replacing the value at
  the passed index with the current value in the state.

  After placing the stone on the board, the current_color player is swapped, to
  prepare the state for the other player's move.

    iex> GameBoard.place_on_board(%State{positions: [nil, nil, nil, nil], current_color: :black}, 0)
    %GameBoard{positions: [:black, nil, nil, nil], current_color: :white}

  Stones are captured if they're surrounded by the opponent's stones. After
  placing a new stone, all stones on the board are checked to see if they have
  any liberties left. If they don't they're removed from the board.
  A *liberty* is an empty position adjacent to a stone. If a stone is
  surrounded by the opponent's stones, it has no liberties left. If two stones
  of the same color are in adjacent positions, they form a group and share
  their liberties.
  After removing a stone from the board, `place_on_board/2` increments the key
  corresponding to the captured stone in the captures counte

    iex> GameBoard.place_on_board(
      ...>   %GameBoard{
      ...>     positions: [
      ...>       :white, :black, nil,
      ...>       nil,    nil,    :white,
      ...>       nil,    nil,    nil
      ...>     ],
      ...>     current_color: :black
      ...>   },
      ...> 3)
      %GameBoard{
        positions: [
          nil,   :black,  nil,
          :black, nil,    :white,
          nil,    nil,    nil
        ],
        current_color: :white,
        captures: %{black: 0, white: 1}
      }

  When placing a stone `place_on_board/2` iterates over the opponents' stones to check
  for captures first. After that, it checks all of the current player's stones.

  Moves aren't validated in the `place_on_board/2` function. This means a placing a
  stone on a position without liberties will immediately remove it from the
  board.

      iex> GameBoard.place_on_board(
      ...>   %GameBoard{
      ...>     positions: [
      ...>       nil,    :black, nil,
      ...>       :black, nil,    :white,
      ...>       nil,    nil,    nil
      ...>     ],
      ...>     current_color: :white
      ...>   },
      ...> 0)
      %GameBoard{
        positions: [
          nil,   :black,  nil,
          :black, nil,    :white,
          nil,    nil,    nil
        ],
        current_color: :white,
        captures: %{black: 0, white: 0}
      }
  """
  @spec place_on_board(GameBoard.t(), integer()) :: GameBoard.t()
  def place_on_board(
        %GameBoard{positions: positions, current_color: current_color, captures: captures} =
          state,
        index
      ) do
    opponent_color = get_opponent_color(current_color)

    changes_positions = List.replace_at(positions, index, current_color)
    {update_positions, opponent_captures} = set_captures(changes_positions, opponent_color)
    {new_positions, _} = set_captures(update_positions, current_color)

    {_, new_captures} =
      Map.get_and_update(captures, opponent_color, fn current ->
        {current, current + opponent_captures}
      end)

    new_current_color =
      case new_positions do
        ^positions -> current_color
        _ -> opponent_color
      end

    %{state | positions: new_positions, current_color: new_current_color, captures: new_captures}
  end

  defp get_opponent_color(:black), do: :white
  defp get_opponent_color(:white), do: :black

  defp set_captures(positions, color) do
    positions
    |> Enum.with_index()
    |> Enum.map_reduce(0, fn {value, index}, captures ->
      case {value, has_liberties?(positions, index, color)} do
        {^color, false} -> {nil, captures + 1}
        {_, _} -> {value, captures}
      end
    end)
  end

  defp has_liberties?(positions, index, color, checked \\ []) do
    size =
      positions
      |> length()
      |> :math.sqrt()
      |> round()

    index
    |> get_liberty_indexes(size)
    |> Enum.reject(&(&1 in checked))
    |> Enum.any?(fn liberty ->
      case Enum.at(positions, liberty) do
        ^color -> has_liberties?(positions, liberty, color, [index | checked])
        nil -> true
        _ -> false
      end
    end)
  end

  defp get_liberty_indexes(index, size) do
    row = div(index, size)
    column = rem(index, size)

    [
      {row - 1, column},
      {row, column + 1},
      {row + 1, column},
      {row, column - 1}
    ]
    |> Enum.reduce([], fn {row, column}, acc ->
      case row < 0 or row >= size or column < 0 or column >= size do
        true -> acc
        false -> [row * size + column | acc]
      end
    end)
  end
end
