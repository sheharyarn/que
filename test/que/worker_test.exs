defmodule Que.Test.Worker do
  use ExUnit.Case

  test "compilation fails if the worker doesn't export a perform/1 method" do
    assert_raise(Que.Error.InvalidWorker, ~r/must export a perform\/1 method/, fn ->
      defmodule InvalidWorker do
        use Que.Worker
      end
    end)
  end

end
