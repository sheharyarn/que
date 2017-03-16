defmodule Que.Test.Job do
  use ExUnit.Case

  alias Que.Test.TestWorker


  test "#new builds a new Job struct with defaults" do
    job = Que.Job.new(TestWorker)

    assert job.worker    == TestWorker
    assert job.status    == :queued
    assert job.arguments == nil
    assert job.ref       == nil
    assert job.pid       == nil
  end


  test "#new accepts arguments" do
    job = Que.Job.new(TestWorker, a: 1, b: 2)
    assert job.arguments == [a: 1, b: 2]
  end


  test "#set_status updates job status to the specified value" do
    job =
      TestWorker
      |> Que.Job.new
      |> Que.Job.set_status(:completed)

    assert job.status == :completed
  end


  test "#set_status raises error if the status is not one of predefined values" do
    assert_raise(FunctionClauseError, fn ->
      TestWorker
      |> Que.Job.new
      |> Que.Job.set_status(:unknown_value)
    end)
  end


  test "#perform works as expected" do
    job =
      TestWorker
      |> Que.Job.new
      |> Que.Job.perform

    assert job.status == :started
    refute job.pid    == nil
    refute job.ref    == nil
  end

end
