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
    jobs  = [1, 2, 3]
    q = Que.JobQueue.new(TestWorker, jobs)

    assert q.__struct__ == Que.JobQueue
    assert q.queued     == jobs
  end

end

