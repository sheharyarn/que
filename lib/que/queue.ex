defmodule Que.Queue do
  defstruct [:worker, :queued, :running]

  @concurrency 4


  @doc """
  Returns a new processable Queue with defaults
  """
  def new(worker, jobs \\ []) do
    %Que.Queue{
      worker:  worker,
      queued:  jobs,
      running: []
    }
  end



  def process(%Que.Queue{running: running} = q) when length(running) < @concurrency do
    case pop(q) do
      {q, nil} -> q
      {q, job} -> %{ q | running: running ++ [Que.Job.perform(job)] }
    end
  end

  def process(queue), do: queue



  @doc """
  Pushes one or more Jobs to the `queued` list
  """
  def push(%Que.Queue{queued: queued} = q, jobs) when is_list(jobs) do
    %{ q | queued: queued ++ jobs }
  end

  def push(queue, job) do
    push(queue, [job])
  end



  @doc """
  Pops the next Job in queue and returns a queue and Job tuple
  """
  def pop(%Que.Queue{queued: [ job | rest ]} = q) do
    { %{ q | queued: rest }, job }
  end

  def pop(%Que.Queue{queued: []} = q) do
    { q, nil }
  end



  @doc """
  Finds a Job in the Queue by the given Job's id, replaces it and
  returns an updated Queue
  """
  def update(%Que.Queue{} = q, %Que.Job{} = job) do
    queued_index = Enum.find_index(q.queued, &(&1.id == job.id))

    if queued_index do
      queued = List.replace_at(q.queued, queued_index, job)
      %{ q | queued: queued }

    else
      running_index = Enum.find_index(q.running, &(&1.id == job.id))

      if running_index do
        running = List.replace_at(q.running, running_index, job)
        %{ q | running: running }

      else
        raise "Job not found in Queue"
      end
    end
  end



  @doc """
  Removes the specified Job from `running`
  """
  def remove(%Que.Queue{} = q, %Que.Job{} = job) do
    index = Enum.find_index(q.running, &(&1.id == job.id))

    if index do
      %{ q | running: List.delete_at(q.running, index) }
    else
      raise "Job not found in Queue"
    end
  end

end
