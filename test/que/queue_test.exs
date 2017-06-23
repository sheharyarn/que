defmodule Que.Test.Queue do
  use ExUnit.Case

  alias Que.Job
  alias Que.Queue

  alias Que.Test.Meta.Helpers
  alias Que.Test.Meta.TestWorker
  alias Que.Test.Meta.ConcurrentWorker


  test "#new builds a new job queue with defaults" do
    q = Queue.new(TestWorker)

    assert q.__struct__     == Queue
    assert q.worker         == TestWorker
    assert Queue.queued(q)  == []
    assert Queue.running(q) == []
  end


  test "#new builds a new job queue with specified jobs" do
    q = Queue.new(TestWorker, [1, 2, 3])

    assert q.__struct__    == Queue
    assert Queue.queued(q) == [1, 2, 3]
  end


  test "#queued returns list of queued jobs in the queue" do
    j1 = []
    j2 = [1,2,3,4,5,6,7]

    q1 = %Queue{queued: :queue.from_list(j1)}
    q2 = %Queue{queued: :queue.from_list(j2)}

    assert Queue.queued(q1) == j1
    assert Queue.queued(q2) == j2
  end


  test "#running returns list of running jobs in the queue" do
    j1 = []
    j2 = [1,2,3,4,5,6,7]

    q1 = %Queue{running: j1}
    q2 = %Queue{running: j2}

    assert Queue.running(q1) == j1
    assert Queue.running(q2) == j2
  end


  test "#put adds a single job to the queued list" do
    q =
      TestWorker
      |> Queue.new([1, 2, 3])
      |> Queue.put(4)

    assert Queue.queued(q) == [1, 2, 3, 4]
  end


  test "#put adds multiple jobs to the queued list" do
    q =
      TestWorker
      |> Queue.new([1, 2, 3])
      |> Queue.put([4, 5, 6, 7])

    assert Queue.queued(q) == [1, 2, 3, 4, 5, 6, 7]
  end


  test "#fetch gets the next job in queue and removes it from the list" do
    {q, job} =
      TestWorker
      |> Queue.new([1, 2, 3])
      |> Queue.fetch

    assert job             == 1
    assert Queue.queued(q) == [2, 3]
  end


  test "#fetch returns nil for empty queues" do
    {q, job} =
      TestWorker
      |> Queue.new
      |> Queue.fetch

    assert job             == nil
    assert Queue.queued(q) == []
  end


  test "#process starts the next job in queue and appends it to running" do
    capture = Helpers.capture_log(fn ->
      q =
        TestWorker
        |> Queue.new([Job.new(TestWorker)])
        |> Queue.process

      assert [%Job{status: :started}] = Queue.running(q)
      assert [] == Queue.queued(q)

      Helpers.wait
    end)

    assert capture =~ ~r/Starting/
  end


  test "#process does nothing when there is nothing in queue" do
    q_before = Queue.new(TestWorker)
    q_after  = Queue.process(q_before)

    assert q_after                == q_before
    assert Queue.queued(q_after)  == []
    assert Queue.running(q_after) == []
  end


  test "#process concurrently runs the specified no. of jobs" do
    capture = Helpers.capture_log(fn ->
      jobs =
        for i <- 1..4, do: Job.new(ConcurrentWorker, :"job_#{i}")

      q =
        ConcurrentWorker
        |> Queue.new(jobs)
        |> Queue.process
        |> Queue.process
        |> Queue.process
        |> Queue.process

      running = Queue.running(q)

      assert [] == Queue.queued(q)
      assert 4  == length(running)

      Enum.each(running, fn j ->
        assert %Job{status: :started} = j
      end)

      Helpers.wait
    end)

    assert capture =~ ~r/Starting/

    assert capture =~ ~r/perform: :job_1/
    assert capture =~ ~r/perform: :job_2/
    assert capture =~ ~r/perform: :job_3/
    assert capture =~ ~r/perform: :job_4/
  end


  test "#find finds the job by id when no field is specified" do
    job =
      TestWorker
      |> Queue.new(sample_job_list())
      |> Queue.find(:x)

    assert job.id     == :x
    assert job.status == :failed
  end


  test "#find finds the job by the given field" do
    job =
      TestWorker
      |> Queue.new(sample_job_list())
      |> Queue.find(:status, :failed)

    assert job.id     == :x
    assert job.status == :failed
  end


  test "#find returns nil when no results are found" do
    job =
      TestWorker
      |> Queue.new(sample_job_list())
      |> Queue.find(:y)

    assert job == nil
  end


  test "#update raises an error if the job doesn't exist in the queue" do
    assert_raise(Que.Error.JobNotFound, ~r/Job not found/, fn ->
      job = Job.new(TestWorker)
      q   = Queue.new(TestWorker)

      Queue.update(q, job)
    end)
  end


  test "#update updates a job in queued" do
    q = %Queue{ queued: :queue.from_list(sample_job_list()), running: [] }

    [_, _, _, job | _] = Queue.queued(q)
    assert job.id     == :x
    assert job.status == :failed

    q = Queue.update(q, %{ job | status: :queued })

    [_, _, _, job | _] = Queue.queued(q)
    assert job.status == :queued
  end


  test "#update updates a job in running" do
    q = %{ running: [_, _, _, job | _] } = %Queue{ queued: :queue.from_list([]), running: sample_job_list() }

    assert job.id     == :x
    assert job.status == :failed

    %{ running: [_, _, _, job | _] } = Queue.update(q, %{ job | status: :completed })

    assert job.status == :completed
  end


  test "#remove deletes a job from running in Queue" do
    q = %{ running: [_, _, _, job | _] } =
      %Queue{ queued: :queue.new(), running: sample_job_list() }

    assert length(Queue.running(q)) == 6

    q = Queue.remove(q, job)

    assert length(Queue.running(q)) == 5
    refute Enum.member?(Queue.running(q), job)
  end


  test "#remove raises an error if Job isn't in queue" do
    assert_raise(Que.Error.JobNotFound, ~r/Job not found/, fn ->
      job = Job.new(TestWorker)
      q   = Queue.new(TestWorker)

      Queue.remove(q, job)
    end)
  end


  ## Private

  defp sample_job_list do
    [
      Job.new(TestWorker),
      Job.new(TestWorker),
      Job.new(TestWorker),
      %Job{ worker: TestWorker, id: :x, status: :failed },
      Job.new(TestWorker),
      Job.new(TestWorker)
    ]
  end
end

