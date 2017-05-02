defmodule Que.ServerSupervisor do
  use Supervisor

  @moduledoc """
  This Supervisor is responsible for spawning a `Que.Server`
  for each worker. You shouldn't start this manually unless
  you absolutely know what you're doing.
  """




  @doc """
  Starts the Supervision Tree
  """
  @spec start_link() :: Supervisor.on_start
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end




  @doc false
  def init(:ok) do
    children = [
      worker(Que.Server, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

end
