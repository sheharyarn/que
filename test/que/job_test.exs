defmodule Que.Test.Job do
  use ExUnit.Case

  alias Que.Job
  alias Que.Test.Meta.Helpers
  alias Que.Test.Meta.TestWorker


  test "#new builds a new Job struct with defaults" do
    job = Job.new(TestWorker)

    assert job.__struct__ == Job
    assert job.worker     == TestWorker
    assert job.status     == :queued
    assert job.arguments  == nil
    assert job.ref        == nil
    assert job.pid        == nil
  end


  test "#new accepts arguments" do
    job = Job.new(TestWorker, a: 1, b: 2)
    assert job.arguments == [a: 1, b: 2]
  end


  test "#set_status updates job status to the specified value" do
    job =
      TestWorker
      |> Job.new
      |> Job.set_status(:completed)

    assert job.status == :completed
  end


  test "#set_status raises error if the status is not one of predefined values" do
    assert_raise(FunctionClauseError, fn ->
      TestWorker
      |> Job.new
      |> Job.set_status(:unknown_value)
    end)
  end


  test "#perform works as expected" do
    capture = Helpers.capture_log(fn ->
      job =
        TestWorker
        |> Job.new
        |> Job.perform

      assert job.status == :started
      refute job.pid    == nil
      refute job.ref    == nil
    end)

    assert capture =~ ~r/Starting Job/
  end

end
