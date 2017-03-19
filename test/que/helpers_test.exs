defmodule Que.Test.Helpers do
  use ExUnit.Case

  alias Que.Test.Meta.Helpers


  test "#log logs text with Que prefix" do
    capture = Helpers.capture_log(fn ->
      Que.Helpers.log("something")
    end)

    assert capture =~ "Que"
    assert capture =~ "something"
  end


  @tag :pending
  test "#do_task works as expected" do
    raise "pending test"
  end

end
