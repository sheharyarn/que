defmodule Que.Server do
  use GenServer

  @name __MODULE__


  @moduledoc """
  `Que.Server` is the `GenServer` responsible for processing all Jobs.

  This `GenServer` oversees the Workers performing their Jobs and handles
  their success and failure callbacks. You shouldn't call any of this
  module's methods directly. Instead use the methods exported by the
  base `Que` module.
  """



  @doc """
  Starts the Job Server
  """
  @spec start_link() :: GenServer.on_start
  def start_link do
    GenServer.start_link(@name, :ok, name: @name)
  end




  ## Internal Callbacks
  ## ------------------


  # Validates worker and creates a new job with the passed
  # arguments. Use Que.add instead of directly calling this

  @doc false
  def add(worker, arg) do
    validate_worker!(worker)
    GenServer.call(@name, {:add_job, worker, arg})
  end



  # Initial State with Empty Queue and a list of currently running jobs

  @doc false
  def init(:ok) do
    Que.Persistence.initialize
    existing_jobs = Que.QueueSet.collect(Que.Persistence.incomplete)

    {:ok, existing_jobs}
  end



  # Pushes a new Job to the queue and processes it

  @doc false
  def handle_call({:add_job, worker, args}, _from, qset) do
    Que.Helpers.log("Queued new Job for #{ExUtils.Module.name(worker)}")

    job =
      worker
      |> Que.Job.new(args)
      |> Que.Persistence.insert

    qset =
      qset
      |> Que.QueueSet.add(job)
      |> Que.QueueSet.process

    {:reply, :ok, qset}
  end



  # Job was completed successfully - Does cleanup and executes the Success
  # callback on the Worker

  @doc false
  def handle_info({:DOWN, ref, :process, _pid, :normal}, qset) do
    job =
      qset
      |> Que.QueueSet.find(:ref, ref)
      |> Que.Job.handle_success
      |> Que.Persistence.update

    qset =
      qset
      |> Que.QueueSet.remove(job)
      |> Que.QueueSet.process

    {:noreply, qset}
  end



  # Job failed / crashed - Does cleanup and executes the Error callback

  @doc false
  def handle_info({:DOWN, ref, :process, _pid, err}, qset) do
    job =
      qset
      |> Que.QueueSet.find(:ref, ref)
      |> Que.Job.handle_failure(err)
      |> Que.Persistence.update

    qset =
      qset
      |> Que.QueueSet.remove(job)
      |> Que.QueueSet.process

    {:noreply, qset}
  end



  # Verifies that the worker is valid, otherwise raises an error

  defp validate_worker!(worker) do
    if Que.Worker.valid?(worker) do
      :ok
    else
      raise Que.Error.InvalidWorker, "#{ExUtils.Module.name(worker)} is an Invalid Worker"
    end
  end

end

