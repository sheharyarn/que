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
  @spec start_link() :: Supervisor.on_start()
  def start_link do
    # Initialize Mnesia DB for Jobs
    Que.Persistence.initialize()

    # Start Supervision Tree
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  def init(:ok) do
    children = [
      {Task.Supervisor, name: Que.TaskSupervisor},
      {Que.ServerSupervisor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
