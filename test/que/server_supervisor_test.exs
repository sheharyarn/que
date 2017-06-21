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


  test "loads and processes existing jobs when app starts" do
    Helpers.App.stop

    1..4
    |> Enum.map(&Que.Job.new(TestWorker, :"job_#{&1}"))
    |> Enum.map(&Que.Persistence.insert/1)

    capture = Helpers.capture_log(fn ->
      Helpers.App.start
      Helpers.wait
    end)

    assert capture =~ ~r/perform: :job_1/
    assert capture =~ ~r/perform: :job_2/
    assert capture =~ ~r/perform: :job_3/
    assert capture =~ ~r/perform: :job_4/
  end
end
