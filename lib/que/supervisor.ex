defmodule Que.Supervisor do
  use Supervisor

  @moduledoc """
  This is the `Supervisor` responsible for overseeing the entire
  `Que` application. You shouldn't start this manually unless
  you absolutely know what you're doing.
  """



  @doc """
  Starts the Supervision Tree for `Que`
  """
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end



  @doc false
  def init(:ok) do
    children = [
      supervisor(Task.Supervisor, [[name: Que.TaskSupervisor]]),
      worker(Que.Server, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

end
