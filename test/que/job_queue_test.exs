defmodule Que.Test.JobQueue do
  use ExUnit.Case


  test "#new builds a new job queue with defaults" do
    q = Que.JobQueue.new(TestWorker)

    assert q.__struct__ == Que.JobQueue
    assert q.worker     == TestWorker
    assert q.queued     == []
    assert q.running    == []
  end


  test "#new builds a new job queue with specified jobs" do
    q = Que.JobQueue.new(TestWorker, [1, 2, 3])

    assert q.__struct__ == Que.JobQueue
    assert q.queued     == [1, 2, 3]
  end


  test "#push adds a single job to the queued list" do
    q =
      TestWorker
      |> Que.JobQueue.new([1, 2, 3])
      |> Que.JobQueue.push(4)

    assert q.queued == [1, 2, 3, 4]
  end


  test "#push adds multiple jobs to the queued list" do
    q =
      TestWorker
      |> Que.JobQueue.new([1, 2, 3])
      |> Que.JobQueue.push([4, 5, 6, 7])

    assert q.queued == [1, 2, 3, 4, 5, 6, 7]
  end

end

