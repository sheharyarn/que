defmodule Que.QueueSet do
  defstruct queues: %{}


  @doc """
  Returns a new QueueSet with defaults
  """
  def new do
    %Que.QueueSet{}
  end

  def add(job)

  def update(job)

  def find_by_ref(ref)

  def load_incomplete

end
