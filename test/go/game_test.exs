defmodule Go.GameTest do
  use ExUnit.Case

  alias Go.Game
  alias Go.GameBoard

  describe "state/1" do
    test "returns the game's current state" do
      state = %GameBoard{current_color: :white}

      assert Game.state(%Game{history: [state, %GameBoard{}]}) == state
    end

    test "returns a game's previous state" do
      state = %GameBoard{current_color: :white}

      assert Game.state(%Game{history: [%GameBoard{}, state], index: 1}) == state
    end
  end

  describe "place/2" do
    test "adds a state to the history to place a stone on the board" do
      expected_game = %Game{
        history: [
          %GameBoard{positions: [:black, nil, nil, nil], current_color: :white},
          %GameBoard{positions: [nil, nil, nil, nil], current_color: :black}
        ]
      }
      game =  %Game{history: [%GameBoard{positions: [nil, nil, nil, nil], current_color: :black}]}

      assert expected_game == Game.place(game, 0)
    end
  end

  describe "jump/2" do
    test "jump/2 updates the game's index attribute" do
      assert %Game{index: 1} = Game.jump(%Game{history: [%GameBoard{}, %GameBoard{}]}, 1)
    end
  end

  describe "has_history?/2" do
    test "returns true for an existing index" do
      assert Game.has_history?(%Game{}, 0)
      assert Game.has_history?(%Game{history: [%GameBoard{}, %GameBoard{}]}, 1)
    end

    test "returns false for a negative index" do
      refute Game.has_history?(%Game{}, -1)
    end

    test "returns false for an index that exceeds the history list indexes" do
      refute Game.has_history?(%Game{}, -1)
    end
  end

  describe "legal?/2" do
    test "is legal when placing a stone on an empty board" do
      assert Game.legal?(%Game{}, 0)
    end

    test "is illegal when placing a stone on a point that's occupied" do
      refute Game.legal?(%Game{history: [%GameBoard{positions: [:white, nil, nil, nil]}]}, 0)
    end

    test "is illegal when the move would revert the game to a previous state (ko)" do
      refute Game.legal?(
               %Game{
                 history: [
                   %GameBoard{positions: [nil, nil, nil, nil], current_color: :white},
                   %GameBoard{positions: [:white, nil, nil, nil], current_color: :black}
                 ]
               },
               0
             )
    end

    test "does not take reverted history into account when enforcing the ko rule" do
      assert(
        Game.legal?(
          %Game{
            history: [
              %GameBoard{positions: [:white, nil, nil, nil], current_color: :black},
              %GameBoard{positions: [nil, nil, nil, nil], current_color: :white}
            ],
            index: 1
          },
          0
        )
      )
    end
  end
end
