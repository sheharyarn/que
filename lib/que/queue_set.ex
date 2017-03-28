defmodule Que.QueueSet do
  defstruct queues: %{}


  @doc """
  Returns a new QueueSet with defaults
  """
  def new do
    %Que.QueueSet{}
  end


  @doc """
  Finds the Queue for a specified worker. If the queue does not
  exist, returns a new Queue for that worker.
  """
  def get(%Que.QueueSet{} = qset, worker) do
    qset.queues[worker] || Que.Queue.new(worker)
  end


  def add(job)

  def update(job)

  def find_by_ref(ref)

  def load_incomplete

end
