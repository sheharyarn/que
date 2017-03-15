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

  def push(%Que.JobQueue{} = q, job) do
    push(q, [job])
  end

end
