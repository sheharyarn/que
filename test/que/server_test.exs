defmodule Que.Test.Server do
  use ExUnit.Case

  alias Que.Test.Meta.Helpers
  alias Que.Test.Meta.TestWorker

  setup do
    Helpers.App.reset
  end


  test "#add queues a job for (previously started) worker server" do
    capture = Helpers.capture_log(fn ->
      Que.Server.start_link(TestWorker)
      Que.Server.add(TestWorker, :yo)
      Helpers.wait
      Que.Server.stop(TestWorker)
    end)

    assert capture =~ ~r/perform: :yo/
  end


  test "loads and processes existing jobs when server starts" do
    1..4
    |> Enum.map(&Que.Job.new(TestWorker, :"job_#{&1}"))
    |> Enum.map(&Que.Persistence.insert/1)

    capture = Helpers.capture_log(fn ->
      Que.Server.start_link(TestWorker)
      Helpers.wait
    end)

    assert capture =~ ~r/perform: :job_1/
    assert capture =~ ~r/perform: :job_2/
    assert capture =~ ~r/perform: :job_3/
    assert capture =~ ~r/perform: :job_4/
  end


  @tag :pending
  test "#handle_info calls success callback & updates queue on job completion" do
    flunk "pending test"
  end


  @tag :pending
  test "#handle_info calls error callback & updates queue on job failure" do
    flunk "pending test"
  end


  test "#exists? is falsy when a server for a given worker isn't running" do
    refute Que.Server.exists?(InvalidWorker)
  end


  test "#exists? returns server pid when a server for a given worker is running" do
    {:ok, pid} = Que.Server.start_link(TestWorker)

    assert pid == Que.Server.exists?(TestWorker)

    Que.Server.stop(TestWorker)
  end

end
