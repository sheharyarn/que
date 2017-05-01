defmodule Que.Persistence do
  @moduledoc """
  Provides a high-level API to interact with Jobs in Database

  This module is a behaviour that delegates calls to the specified
  adapter. It has been designed in a way that it's easy to write
  custom adapters for other databases or stores like Redis, even
  though there are no current plans on supporting anything other
  than `Mnesia`.
  """


  ## Adapter to delegate all methods to
  @adapter Que.Persistence.Mnesia




  @doc """
  Finds a `Que.Job` from the database.

  Returns the a Job struct if it's found, otherwise `nil`.
  """
  @spec find(id :: integer) :: Que.Job.t | nil
  defdelegate find(id), to: @adapter




  @doc """
  Deletes a `Que.Job` from the database.
  """
  @spec destroy(id :: integer) :: :ok | no_return
  defdelegate destroy(id), to: @adapter




  @doc """
  Inserts a `Que.Job` into the database.

  Returns the same Job struct with the `id` value set
  """
  @spec insert(job :: Que.Job.t) :: Que.Job.t
  defdelegate insert(job), to: @adapter




  @doc """
  Updates an existing `Que.Job` in the database.

  This methods finds the job to update by the given
  job's id. If no job with the given id exists, it is
  inserted as-is. If the id of the given job is nil,
  it's still inserted and a valid id is assigned.

  Returns the updated job.
  """
  @spec update(job :: Que.Job.t) :: Que.Job.t
  defdelegate update(job), to: @adapter




  @doc """
  Returns all `Que.Job`s in the database.
  """
  @spec all :: list(Que.Job.t)
  defdelegate all, to: @adapter




  @doc """
  Returns all `Que.Job`s for the given worker.
  """
  @spec all(worker :: Que.Worker.t) :: list(Que.Job.t)
  defdelegate all(worker), to: @adapter




  @doc """
  Returns completed `Que.Job`s from the database.
  """
  @spec completed :: list(Que.Job.t)
  defdelegate completed, to: @adapter




  @doc """
  Returns incomplete `Que.Job`s from the database.

  This includes all Jobs whose status is either
  `:queued` or `:started` but not `:failed`.
  """
  @spec incomplete :: list(Que.Job.t)
  defdelegate incomplete, to: @adapter




  @doc """
  Returns failed `Que.Job`s from the database.
  """
  @spec failed :: list(Que.Job.t)
  defdelegate failed, to: @adapter




  @doc """
  Makes sure that the Database is ready to be used.

  This is called when the Que application, specifically
  `Que.Server`, starts to make sure that a database exists
  and is ready to be used.
  """
  @spec initialize :: :ok | :error
  defdelegate initialize, to: @adapter




  # Macro so future adapters `use` this module
  defmacro __using__(_opts) do
    quote do
      @parent unquote(__MODULE__)
    end
  end

end
