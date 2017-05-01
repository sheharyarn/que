defmodule Que.QueueSet do
  defstruct queues: %{}


  @moduledoc """
  Module to manage a QueueSet comprising of multiple `Que.Queue`s,
  each for their respective `Que.Worker.t`.

  Maintains a collection for Queues, one per `Que.Worker`, and
  provides wrappers around it for managing Jobs. Checks a given
  `Que.Job`'s type and off-loads the operation to the proper Queue
  and Worker pair.

  There should be only one `QueueSet` per Que application.
  Meant for internal usage, so you shouldn't use this unless you
  absolutely know what you're doing.
  """


  @typedoc  "A `Que.QueueSet` struct"
  @type     t :: %Que.QueueSet{}




  @doc """
  Returns a new QueueSet with defaults
  """
  @spec new :: Que.QueueSet.t
  def new do
    %Que.QueueSet{}
  end




  @doc """
  Finds the Queue for a specified worker. If the queue does not
  exist, returns a new Queue for that worker.
  """
  @spec get(queue_set :: Que.QueueSet.t, worker :: Que.Worker.t) :: Que.Queue.t
  def get(%Que.QueueSet{} = qset, worker) do
    qset.queues[worker] || Que.Queue.new(worker)
  end




  @doc """
  Adds a Job to the appropriate Queue in a QueueSet
  """
  @spec add(queue_set :: Que.QueueSet.t, job :: Que.Job.t) :: Que.QueueSet.t
  def add(%Que.QueueSet{} = qset, %Que.Job{} = job) do
    q =
      qset
      |> Que.QueueSet.get(job.worker)
      |> Que.Queue.put(job)

    %{ qset | queues: Map.put(qset.queues, job.worker, q) }
  end




  @doc """
  Finds a Job in the QueueSet by the given Job's id and updates
  (replaces) it with the specified Job
  """
  @spec update(queue_set :: Que.QueueSet.t, job :: Que.Job.t) :: Que.QueueSet.t
  def update(%Que.QueueSet{} = qset, %Que.Job{} = job) do
    q =
      qset
      |> Que.QueueSet.get(job.worker)
      |> Que.Queue.update(job)

    %{ qset | queues: Map.put(qset.queues, job.worker, q) }
  end




  @doc """
  Removes the specified job from the appropriate Queue's running list
  """
  @spec remove(queue_set :: Que.QueueSet.t, job :: Que.Job.t) :: Que.QueueSet.t
  def remove(%Que.QueueSet{} = qset, %Que.Job{} = job) do
    q =
      qset
      |> Que.QueueSet.get(job.worker)
      |> Que.Queue.remove(job)

    %{ qset | queues: Map.put(qset.queues, job.worker, q) }
  end




  @doc """
  Calles :process on all Queues in QueueSet
  """
  @spec process(queue_set :: Que.QueueSet.t) :: Que.QueueSet.t
  def process(%Que.QueueSet{ queues: queues } = qset) do
    queues =
      queues
      |> Enum.map(fn {w, q} -> {w, Que.Queue.process(q)} end)
      |> Enum.into(%{})

    %{ qset | queues: queues }
  end




  @doc """
  Groups a list of Jobs into a proper QueueSet. All Jobs are loaded
  only in the :queued list
  """
  @spec collect(jobs :: list(Que.Job.t)) :: Que.QueueSet.t
  def collect(jobs) when is_list(jobs) do
    queues =
      jobs
      |> Enum.group_by(&(&1.worker))
      |> Enum.map(fn {w, j} -> {w, Que.Queue.new(w, j)} end)
      |> Enum.into(%{})

    %Que.QueueSet{ queues: queues }
  end




  @doc """
  Finds a Job in a QueueSet by the specified key-value pair.

  If no key is specified, it's assumed to be `:id`.
  """
  @spec find(queue_set :: Que.QueueSet.t, key :: atom, value :: term) :: Que.Job.t | nil
  def find(%Que.QueueSet{ queues: queues }, key \\ :id, value) do
    Enum.find_value(queues, fn {_, q} ->
      Que.Queue.find(q, key, value)
    end)
  end

end
