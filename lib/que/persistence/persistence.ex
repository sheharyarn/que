defmodule Que.Persistence do
  @moduledoc """
  Provides a high-level API to interact with Jobs in Database

  This module is a behaviour that delegates calls to the specified
  adapter. It has been designed in a way that it's easy to write
  custom adapters for other Databases or Stores like Redis, even
  though there are no current plans on supporting any thing other
  than `Mnesia`.
  """


  ## Adapter to delegate all methods to
  @adapter Que.Persistence.Mnesia




  @doc """
  """
  @spec find(id :: integer) :: Que.Job.t
  defdelegate find(id), to: @adapter




  @spec destroy(id :: integer) :: :ok | no_return
  defdelegate destroy(id), to: @adapter




  @spec insert(job :: Que.Job.t) :: Que.Job.t
  defdelegate insert(job), to: @adapter




  @spec update(job :: Que.Job.t) :: Que.Job.t
  defdelegate update(job), to: @adapter




  @spec all :: list(Que.Job.t)
  defdelegate all, to: @adapter




  @spec completed :: list(Que.Job.t)
  defdelegate completed, to: @adapter




  @spec incomplete :: list(Que.Job.t)
  defdelegate incomplete, to: @adapter




  @spec failed :: list(Que.Job.t)
  defdelegate failed, to: @adapter




  @spec for_worker(worker :: Que.Worker.t) :: list(Que.Job.t)
  defdelegate for_worker(worker), to: @adapter




  @spec initialize :: :ok | :error
  defdelegate initialize, to: @adapter




  # Macro so future adapters `use` this module
  defmacro __using__(_opts) do
    quote do
      @parent unquote(__MODULE__)
    end
  end

end
