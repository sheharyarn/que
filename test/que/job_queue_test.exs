defmodule Que.Test.JobQueue do
  use ExUnit.Case

  alias Que.Job
  alias Que.JobQueue
  alias Que.Test.Meta.Helpers
  alias Que.Test.Meta.TestWorker


  test "#new builds a new job queue with defaults" do
    q = JobQueue.new(TestWorker)

    assert q.__struct__ == JobQueue
    assert q.worker     == TestWorker
    assert q.queued     == []
    assert q.running    == []
  end


  test "#new builds a new job queue with specified jobs" do
    q = JobQueue.new(TestWorker, [1, 2, 3])

    assert q.__struct__ == JobQueue
    assert q.queued     == [1, 2, 3]
  end


  test "#push adds a single job to the queued list" do
    q =
      TestWorker
      |> JobQueue.new([1, 2, 3])
      |> JobQueue.push(4)

    assert q.queued == [1, 2, 3, 4]
  end


  test "#push adds multiple jobs to the queued list" do
    q =
      TestWorker
      |> JobQueue.new([1, 2, 3])
      |> JobQueue.push([4, 5, 6, 7])

    assert q.queued == [1, 2, 3, 4, 5, 6, 7]
  end


  test "#pop gets the next job in queue and removes it from the list" do
    {q, job} =
      TestWorker
      |> JobQueue.new([1, 2, 3])
      |> JobQueue.pop

    assert job      == 1
    assert q.queued == [2, 3]
  end


  test "#pop returns nil for empty queues" do
    {q, job} =
      TestWorker
      |> JobQueue.new
      |> JobQueue.pop

    assert job      == nil
    assert q.queued == []
  end


  test "#process starts the next job in queue and appends it to running" do
    capture = Helpers.capture_log(fn ->
      q =
        TestWorker
        |> JobQueue.new([Job.new(TestWorker)])
        |> JobQueue.process

      assert [%Job{status: :started}] = q.running
      assert [] == q.queued
    end)

    assert capture =~ ~r/Starting/
  end


  test "#process does nothing when there is nothing in queue" do
    q_before = JobQueue.new(TestWorker)
    q_after  = JobQueue.process(q_before)

    assert q_after         == q_before
    assert q_after.queued  == []
    assert q_after.running == []
  end

end

