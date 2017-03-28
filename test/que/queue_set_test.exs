defmodule Que.Test.QueueSet do
  use ExUnit.Case

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
    queues =
      [TestWorker, SuccessWorker, FailureWorker]
      |> Enum.map(&({&1, Queue.new(&1)}))
      |> Enum.into(%{})

    qset = %QueueSet{ queues: queues }

    assert QueueSet.get(qset, TestWorker).worker    == TestWorker
    assert QueueSet.get(qset, SuccessWorker).worker == SuccessWorker
    assert QueueSet.get(qset, FailureWorker).worker == FailureWorker
  end


  test "#get returns a new queue for a worker not present in set" do
    q = QueueSet.get(%QueueSet{}, TestWorker)

    assert q.worker ==  TestWorker
    assert q.queued == []
  end

end
