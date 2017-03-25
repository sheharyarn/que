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
  Pops the next job in queue and returns a queue and job tuple
  """
  def pop(%Que.Queue{queued: [ job | rest ]} = q) do
    { %{ q | queued: rest }, job }
  end

  def pop(%Que.Queue{queued: []} = q) do
    { q, nil }
  end

end
