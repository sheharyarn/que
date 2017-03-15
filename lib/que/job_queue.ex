defmodule Que.JobQueue do
  defstruct [:worker, :queued, :running]


  @doc """
  Returns a new processable JobQueue with defaults
  """
  def new(worker, jobs \\ []) do
    %Que.JobQueue{
      worker:  worker,
      queued:  jobs,
      running: []
    }
  end



  @doc """
  Pushes one or more Jobs to the `queued` list
  """
  def push(%Que.JobQueue{queued: queued} = q, jobs) when is_list(jobs) do
    %{ q | queued: queued ++ jobs }
  end

  def push(queue, job) do
    push(queue, [job])
  end



  @doc """
  Pops the next job in queue and returns a queue and job tuple
  """
  def pop(%Que.JobQueue{queued: [ job | rest ]} = q) do
    { %{ q | queued: rest }, job }
  end

  def pop(%Que.JobQueue{queued: []} = q) do
    { q, nil }
  end

end
