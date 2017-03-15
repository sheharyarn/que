defmodule Que.JobQueue do
  defstruct [:worker, :queued, :running]


  @doc """
  Creates a new processable JobQueue with defaults
  """
  def new(worker, jobs \\ []) do
    %Que.JobQueue{
      worker:  worker,
      queued:  jobs,
      running: []
    }
  end

end
