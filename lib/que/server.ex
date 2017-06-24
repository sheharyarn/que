defmodule Que.Server do
  use GenServer

  @module __MODULE__


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
  @spec start_link(worker :: Que.Worker.t) :: GenServer.on_start
  def start_link(worker) do
    Que.Helpers.log("Spawning Server for worker: #{inspect(worker)}", :low)
    GenServer.start_link(@module, {:ok, worker}, name: via_worker(worker))
  end




  @doc """
  Stops the Job Server
  """
  @spec stop(worker :: Que.Worker.t) :: :ok
  def stop(worker) do
    worker
    |> via_worker
    |> GenServer.stop
  end




  ## Internal Callbacks
  ## ------------------


  # Validates worker and creates a new job with the passed
  # arguments. Use Que.add instead of directly calling this

  @doc false
  def add(worker, arg) do
    GenServer.call(via_worker(worker), {:add_job, worker, arg})
  end




  # Initial State with Empty Queue and a list of currently running jobs

  @doc false
  def init({:ok, worker}) do
    existing_jobs =
      Que.Persistence.incomplete(worker)

    queue =
      worker
      |> Que.Queue.new(existing_jobs)
      |> Que.Queue.process

    {:ok, queue}
  end




  # Pushes a new Job to the queue and processes it

  @doc false
  def handle_call({:add_job, worker, args}, _from, queue) do
    Que.Helpers.log("Queued new Job for #{ExUtils.Module.name(worker)}")

    job =
      worker
      |> Que.Job.new(args)
      |> Que.Persistence.insert

    queue =
      queue
      |> Que.Queue.put(job)
      |> Que.Queue.process

    {:reply, :ok, queue}
  end




  # Job was completed successfully - Does cleanup and executes the Success
  # callback on the Worker

  @doc false
  def handle_info({:DOWN, ref, :process, _pid, :normal}, queue) do
    job =
      queue
      |> Que.Queue.find(:ref, ref)
      |> Que.Job.handle_success
      |> Que.Persistence.update

    queue =
      queue
      |> Que.Queue.remove(job)
      |> Que.Queue.process

    {:noreply, queue}
  end




  # Job failed / crashed - Does cleanup and executes the Error callback

  @doc false
  def handle_info({:DOWN, ref, :process, _pid, err}, queue) do
    job =
      queue
      |> Que.Queue.find(:ref, ref)
      |> Que.Job.handle_failure(err)
      |> Que.Persistence.update

    queue =
      queue
      |> Que.Queue.remove(job)
      |> Que.Queue.process

    {:noreply, queue}
  end




  @doc false
  def exists?(worker) do
    worker
    |> via_worker
    |> GenServer.whereis
  end




  # Get Server Name from Worker

  defp via_worker(worker) do
    {:global, {@module, worker}}
  end

end

