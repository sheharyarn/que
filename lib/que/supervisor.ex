defmodule Que.Supervisor do
  use Supervisor

  @moduledoc false
  # Module meant for internal use. Should be started as part of
  # the Que application.

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      supervisor(Task.Supervisor, [[name: Que.TaskSupervisor]]),
      worker(Que.Handler, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end

