defmodule Que.Queue do
  defstruct [:worker, :queued, :running]


  @moduledoc """
  Module to manage a Queue comprising of multiple jobs.

  Responsible for queueing (duh), executing and handling callbacks,
  for `Que.Job`s of a specific `Que.Worker`. Also keeps track of
  running jobs and processes them concurrently (if the worker is
  configured so).

  Meant for internal usage, so you shouldn't use this unless you
  absolutely know what you're doing.
  """


  @typedoc  "A `Que.Queue` struct"
  @type     t :: %Que.Queue{}




  @doc """
  Returns a new processable Queue with defaults
  """
  @spec new(worker :: Que.Worker.t, jobs :: list(Que.Job.t)) :: Que.Queue.t
  def new(worker, jobs \\ []) do
    %Que.Queue{
      worker:  worker,
      queued:  :queue.from_list(jobs),
      running: []
    }
  end




  @doc """
  Processes the Queue and runs pending jobs
  """
  @spec process(queue :: Que.Queue.t) :: Que.Queue.t
  def process(%Que.Queue{running: running, worker: worker} = q) do
    Que.Worker.validate!(worker)

    if (length(running) < worker.concurrency) do
      case fetch(q) do
        {q, nil} ->
          q

        {q, job} ->
          job =
            job
            |> Que.Job.perform
            |> Que.Persistence.update

          %{ q | running: running ++ [job] }
      end

    else
      q
    end
  end




  @doc """
  Adds one or more Jobs to the `queued` list
  """
  @spec put(queue :: Que.Queue.t, jobs :: Que.Job.t | list(Que.Job.t)) :: Que.Queue.t
  def put(%Que.Queue{queued: queued} = q, jobs) when is_list(jobs) do
    jobs = :queue.from_list(jobs)
    %{ q | queued: :queue.join(queued, jobs) }
  end

  def put(%Que.Queue{queued: queued} = q, job) do
    %{ q | queued: :queue.in(job, queued) }
  end




  @doc """
  Fetches the next Job in queue and returns a queue and Job tuple
  """
  @spec fetch(queue :: Que.Queue.t) :: { Que.Queue.t, Que.Job.t | nil }
  def fetch(%Que.Queue{queued: queue} = q) do
    case :queue.out(queue) do
      {{:value, job}, rest} -> { %{ q | queued: rest }, job }
      {:empty, _} -> { q, nil }
    end
  end




  @doc """
  Finds the Job in Queue by the specified key name and value.

  If no key is specified, it's assumed to be an `:id`. If the
  specified key is a :ref, it only searches in the `:running`
  list.
  """
  @spec find(queue :: Que.Queue.t, key :: atom, value :: term) :: Que.Job.t | nil
  def find(queue, key \\ :id, value)

  # job.ref is actually a Task. So, we need to access job.ref.ref to get
  # the real reference of a job.
  def find(%Que.Queue{ running: running }, :ref, value) do
    Enum.find(running, &(Map.get(&1, :ref) |> Map.get(:ref) == value))
  end

  def find(%Que.Queue{} = q, key, value) do
    Enum.find(queued(q),  &(Map.get(&1, key) == value)) ||
    Enum.find(running(q), &(Map.get(&1, key) == value))
  end




  @doc """
  Finds a Job in the Queue by the given Job's id, replaces it and
  returns an updated Queue
  """
  @spec update(queue :: Que.Queue.t, job :: Que.Job.t) :: Que.Queue.t
  def update(%Que.Queue{} = q, %Que.Job{} = job) do
    queued = queued(q)
    queued_index = Enum.find_index(queued, &(&1.id == job.id))

    if queued_index do
      queued = List.replace_at(queued, queued_index, job)
      %{ q | queued: :queue.from_list(queued) }

    else
      running_index = Enum.find_index(q.running, &(&1.id == job.id))

      if running_index do
        running = List.replace_at(q.running, running_index, job)
        %{ q | running: running }

      else
        raise Que.Error.JobNotFound, "Job not found in Queue"
      end
    end
  end




  @doc """
  Removes the specified Job from `running`
  """
  @spec remove(queue :: Que.Queue.t, job :: Que.Job.t) :: Que.Queue.t
  def remove(%Que.Queue{} = q, %Que.Job{} = job) do
    index = Enum.find_index(q.running, &(&1.id == job.id))

    if index do
      %{ q | running: List.delete_at(q.running, index) }
    else
      raise Que.Error.JobNotFound, "Job not found in Queue"
    end
  end




  @doc """
  Returns queued jobs in the Queue
  """
  @spec queued(queue :: Que.Queue.t) :: list(Que.Job.t)
  def queued(%Que.Queue{queued: queued}) do
    :queue.to_list(queued)
  end




  @doc """
  Returns running jobs in the Queue
  """
  @spec running(queue :: Que.Queue.t) :: list(Que.Job.t)
  def running(%Que.Queue{running: running}) do
    running
  end

end
