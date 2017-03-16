defmodule Que.Test.Job do
  use ExUnit.Case


  test "#new builds a new Job struct with defaults" do
    job = Que.Job.new(TestWorker)

    assert job.worker    == TestWorker
    assert job.status    == :queued
    assert job.arguments == nil
  end

end
