defmodule Que.ServerSupervisor do
  use Supervisor

  @module __MODULE__

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
    Supervisor.start_link(@module, :ok, name: @module)
  end




  @doc false
  def init(:ok) do
    children = [
      worker(Que.Server, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

end
