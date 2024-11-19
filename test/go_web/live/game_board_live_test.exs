defmodule GoWeb.GameBoardLiveTest do
  use GoWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  #alias GoWeb.GameBoardLive

  test "renders the board", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/gameboard")

    assert html =~ ~r(<div class="board">.*</div>)s
  end

  test "renders 81 point buttons", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/gameboard")

    assert ~r(<button id="capture".*?></button>)s
           |> Regex.scan(html)
           |> length() == 81
  end

  test "places a stone", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/gameboard")

    assert render_click(lv, "place", %{"index" => "0"}) =~
             ~r(<div.*?>[^>]*?<button id="capture" class="black" disabled="disabled"></button>)s
  end

  test "disables a position", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/gameboard")

    render_click(lv, "place", %{"index" => "1"})

    assert render_click(lv, "place", %{"index" => "9"}) =~
             ~r(<div.*?>[^>]*?<button id="capture" class="black" disabled="disabled"></button>)s
  end

  test "displays captured stones", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/gameboard")

    render_click(lv, "place", %{"index" => "0"})
    render_click(lv, "place", %{"index" => "8"})
    render_click(lv, "place", %{"index" => "17"})
    render_click(lv, "place", %{"index" => "9"})
    render_click(lv, "place", %{"index" => "7"})

    result = render_click(lv, "place", %{"index" => "1"})

    assert result =~ ~r(<span class="black">)s
    assert result =~ ~r(<span class="white">)s
  end
end
