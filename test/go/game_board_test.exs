defmodule Go.GameBoardTest do
  use ExUnit.Case

  alias Go.GameBoard

  describe "board base" do
    test "has has 81 empty positions on start" do
      %GameBoard{positions: positions} = %GameBoard{}

      assert length(positions) == 81
      assert Enum.uniq(positions) == [nil]
    end

    test "black is always the first to move" do
      assert %GameBoard{current_color: :black} = %GameBoard{}
    end
  end

  describe "place_on_board/2" do
    test "place stone on empty board" do
      result = GameBoard.place_on_board(%GameBoard{positions: ~w{nil nil nil nil}a, current_color: :black}, 0)

      assert %GameBoard{
        positions: [:black, nil, nil, nil],
        current_color: :white,
        captures: %{black: 0, white: 0}
      } == result
    end

    test "if place a stone without liberties board do not change and current color dont switch" do
      result = GameBoard.place_on_board(%GameBoard{positions: ~w{nil black black nil}a, current_color: :white}, 0)

      assert %GameBoard{
        positions: [nil, :black, :black, nil],
        current_color: :white,
        captures: %{black: 0, white: 0}
      } == result
    end

    test "removes an opponent's stone, count captures and change board position list" do
      result = GameBoard.place_on_board(%GameBoard{positions: ~w{white black nil nil}a, current_color: :black}, 2)

      assert %GameBoard{
        positions: [nil, :black, :black, nil],
        current_color: :white,
        captures: %{black: 0, white: 1}
      } == result
    end

    test "removes an opponent's group, count captures and change board position list" do
      state = %GameBoard{positions: ~w{white white nil black black nil nil nil nil}a, current_color: :black}
      result = GameBoard.place_on_board(state, 2)

      assert %GameBoard{
        positions: [nil, nil, :black, :black, :black, nil, nil, nil, nil],
        current_color: :white,
        captures: %{black: 0, white: 2}
      } == result
    end

    test "removes a group and gains liberties, count captures and change board position list" do
      state = %GameBoard{positions: ~w{nil black white black white nil white nil nil}a, current_color: :white}
      result = GameBoard.place_on_board(state, 0)

      assert %GameBoard{
        positions: [:white, nil, :white, nil, :white, nil, :white, nil, nil],
        current_color: :black,
        captures: %{black: 2, white: 0}
      } == result
    end
  end
end
