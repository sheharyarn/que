defmodule Que.Test.ServerSupervisor do
  use ExUnit.Case

  alias Que.Test.Meta.Helpers
  alias Que.Test.Meta.TestWorker

  setup do
    Helpers.App.reset
  end


  test "#add raises error for invalid workers" do
    assert_raise(Que.Error.InvalidWorker, ~r/Invalid Worker/, fn ->
      Que.ServerSupervisor.add(InvalidWorker, :random_args)
    end)
  end


  test "#add works fine for 'real' workers" do
    capture = Helpers.capture_log(fn ->
      Que.ServerSupervisor.add(TestWorker, :yo)
      Helpers.wait
    end)

    assert capture =~ ~r/perform: :yo/
  end

end
