defmodule Que.Test.Job do
  use ExUnit.Case


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

end
