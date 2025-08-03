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
  @callback find(id :: integer) :: Que.Job.t | nil
  defdelegate find(id), to: @adapter




  @doc """
  Deletes a `Que.Job` from the database.
  """
  @callback destroy(id :: integer) :: :ok | no_return
  defdelegate destroy(id), to: @adapter




  @doc """
  Inserts a `Que.Job` into the database.

  Returns the same Job struct with the `id` value set
  """
  @callback insert(job :: Que.Job.t) :: Que.Job.t
  defdelegate insert(job), to: @adapter




  @doc """
  Updates an existing `Que.Job` in the database.

  This methods finds the job to update by the given
  job's id. If no job with the given id exists, it is
  inserted as-is. If the id of the given job is nil,
  it's still inserted and a valid id is assigned.

  Returns the updated job.
  """
  @callback update(job :: Que.Job.t) :: Que.Job.t
  defdelegate update(job), to: @adapter




  @doc """
  Returns all `Que.Job`s in the database.
  """
  @callback all :: list(Que.Job.t)
  defdelegate all, to: @adapter




  @doc """
  Returns all `Que.Job`s for the given worker.
  """
  @callback all(worker :: Que.Worker.t) :: list(Que.Job.t)
  defdelegate all(worker), to: @adapter




  @doc """
  Returns completed `Que.Job`s from the database.
  """
  @callback completed :: list(Que.Job.t)
  defdelegate completed, to: @adapter




  @doc """
  Returns completed `Que.Job`s for the given worker.
  """
  @callback completed(worker :: Que.Worker.t) :: list(Que.Job.t)
  defdelegate completed(worker), to: @adapter




  @doc """
  Returns incomplete `Que.Job`s from the database.

  This includes all Jobs whose status is either
  `:queued` or `:started` but not `:failed`.
  """
  @callback incomplete :: list(Que.Job.t)
  defdelegate incomplete, to: @adapter




  @doc """
  Returns incomplete `Que.Job`s for the given worker.
  """
  @callback incomplete(worker :: Que.Worker.t) :: list(Que.Job.t)
  defdelegate incomplete(worker), to: @adapter




  @doc """
  Returns failed `Que.Job`s from the database.
  """
  @callback failed :: list(Que.Job.t)
  defdelegate failed, to: @adapter




  @doc """
  Returns failed `Que.Job`s for the given worker.
  """
  @callback failed(worker :: Que.Worker.t) :: list(Que.Job.t)
  defdelegate failed(worker), to: @adapter


  @doc """
  Returns scheduled `Que.Job`s that are ready to be executed.
  """
  @callback ready_scheduled :: list(Que.Job.t)
  defdelegate ready_scheduled, to: @adapter


  @doc """
  Returns scheduled `Que.Job`s for the given worker that are ready to be executed.
  """
  @callback ready_scheduled(worker :: Que.Worker.t) :: list(Que.Job.t)
  defdelegate ready_scheduled(worker), to: @adapter


  @doc """
  Returns cancelled `Que.Job`s from the database.
  """
  @callback cancelled :: list(Que.Job.t)
  defdelegate cancelled, to: @adapter


  @doc """
  Returns cancelled `Que.Job`s for the given worker.
  """
  @callback cancelled(worker :: Que.Worker.t) :: list(Que.Job.t)
  defdelegate cancelled(worker), to: @adapter


  @doc """
  Returns cancellable `Que.Job`s from the database.

  This includes all Jobs whose status is either `:scheduled` or `:queued`.
  """
  @callback cancellable :: list(Que.Job.t)
  defdelegate cancellable, to: @adapter


  @doc """
  Returns cancellable `Que.Job`s for the given worker.
  """
  @callback cancellable(worker :: Que.Worker.t) :: list(Que.Job.t)
  defdelegate cancellable(worker), to: @adapter


  @doc """
  Returns retrying `Que.Job`s from the database.
  """
  @callback retrying :: list(Que.Job.t)
  defdelegate retrying, to: @adapter


  @doc """
  Returns retrying `Que.Job`s for the given worker.
  """
  @callback retrying(worker :: Que.Worker.t) :: list(Que.Job.t)
  defdelegate retrying(worker), to: @adapter


  @doc """
  Returns timeout `Que.Job`s from the database.
  """
  @callback timeout :: list(Que.Job.t)
  defdelegate timeout, to: @adapter


  @doc """
  Returns timeout `Que.Job`s for the given worker.
  """
  @callback timeout(worker :: Que.Worker.t) :: list(Que.Job.t)
  defdelegate timeout(worker), to: @adapter




  @doc """
  Makes sure that the Database is ready to be used.

  This is called when the Que application, specifically
  `Que.Server`, starts to make sure that a database exists
  and is ready to be used.
  """
  @callback initialize :: :ok | :error
  defdelegate initialize, to: @adapter




  # Macro so future adapters `use` this module
  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end

end
