defmodule Que.Test.QueueSet do
  use ExUnit.Case

  alias Que.Job
  alias Que.Queue
  alias Que.QueueSet

  alias Que.Test.Meta.TestWorker
  alias Que.Test.Meta.SuccessWorker
  alias Que.Test.Meta.FailureWorker



  test "#new returns a new QueueSet with defaults" do
    qset = QueueSet.new

    assert qset.queues == %{}
  end


  test "#get find the correct Queue for specified worker" do
    qset = sample_queue_set()

    assert QueueSet.get(qset, TestWorker).worker    == TestWorker
    assert QueueSet.get(qset, SuccessWorker).worker == SuccessWorker
    assert QueueSet.get(qset, FailureWorker).worker == FailureWorker
  end


  test "#get returns a new queue for a worker not present in set" do
    q = QueueSet.get(%QueueSet{}, TestWorker)

    refute q        == nil
    assert q.worker == TestWorker
    assert q.queued == []
  end


  test "#add inserts a job into the appropriate queue" do
    job  = Job.new(TestWorker)
    qset = QueueSet.add(sample_queue_set(), job)

    assert qset.queues[TestWorker].queued == [job]
  end


  test "#update updates the job in the appropriate queue" do
    job  = %Job{ id: :x, status: :queued, worker: TestWorker }
    qset = QueueSet.add(sample_queue_set(), job)

    [job] =
      qset
      |> QueueSet.update(%{ job | status: :failed })
      |> QueueSet.get(TestWorker)
      |> Map.get(:queued)

    assert job.id     == :x
    assert job.status == :failed
  end


  test "#remove deletes the job from the running list of the worker queue" do
    job  = %Job{ id: :x, status: :queued, worker: TestWorker }
    q    = %Queue{ worker: TestWorker, queued: [], running: [job] }
    qset = %QueueSet{ queues: %{ TestWorker => q} }

    assert qset.queues[TestWorker].running == [job]

    running =
      qset
      |> QueueSet.remove(job)
      |> QueueSet.get(TestWorker)
      |> Map.get(:running)

    assert running == []
  end


  test "#collect groups a list of jobs into a QueueSet with proper queues" do
    jobs = [
      t1 = Job.new(TestWorker),
      s1 = Job.new(SuccessWorker),
      f1 = Job.new(FailureWorker),
      t2 = Job.new(TestWorker),
      s2 = Job.new(SuccessWorker),
      f2 = Job.new(FailureWorker)
    ]

    qset = QueueSet.collect(jobs)

    assert qset.queues == %{
      TestWorker    => Queue.new(TestWorker,    [t1, t2]),
      SuccessWorker => Queue.new(SuccessWorker, [s1, s2]),
      FailureWorker => Queue.new(FailureWorker, [f1, f2])
    }
  end


  ## Private

  defp sample_queue_set do
    queues =
      [TestWorker, SuccessWorker, FailureWorker]
      |> Enum.map(&({ &1, Queue.new(&1) }))
      |> Enum.into(%{})

    %QueueSet{ queues: queues }
  end

end
