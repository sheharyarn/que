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
  def add(worker, arg, opts \\ []) do
    GenServer.call(via_worker(worker), {:add_job, worker, arg, opts})
  end

  # Validates worker and creates a new scheduled job with the passed
  # arguments. Use Que.add_scheduled instead of directly calling this

  @doc false
  def add_scheduled(worker, arg, scheduled_at, opts \\ []) do
    GenServer.call(via_worker(worker), {:add_scheduled_job, worker, arg, scheduled_at, opts})
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
  def handle_call({:add_job, worker, args, opts}, _from, queue) do
    Que.Helpers.log("Queued new Job for #{ExUtils.Module.name(worker)}")

    job =
      worker
      |> Que.Job.new(args, opts)
      |> Que.Persistence.insert

    queue =
      queue
      |> Que.Queue.put(job)
      |> Que.Queue.process

    {:reply, {:ok, job}, queue}
  end

  # Backward compatibility - handle old API without opts
  @doc false
  def handle_call({:add_job, worker, args}, from, queue) do
    handle_call({:add_job, worker, args, []}, from, queue)
  end

  # Pushes a new scheduled Job to the queue

  @doc false
  def handle_call({:add_scheduled_job, worker, args, scheduled_at, opts}, _from, queue) do
    Que.Helpers.log("Scheduled new Job for #{ExUtils.Module.name(worker)} at #{scheduled_at}")

    job =
      worker
      |> Que.Job.new_scheduled(args, scheduled_at, opts)
      |> Que.Persistence.insert

    queue =
      queue
      |> Que.Queue.put(job)
      |> Que.Queue.process

    {:reply, {:ok, job}, queue}
  end

  # Backward compatibility - handle old API without opts
  @doc false
  def handle_call({:add_scheduled_job, worker, args, scheduled_at}, from, queue) do
    handle_call({:add_scheduled_job, worker, args, scheduled_at, []}, from, queue)
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

  # Job timeout - Kill job and handle timeout

  @doc false
  def handle_info({:job_timeout, job_id}, queue) do
    job = Que.Queue.find(queue, :id, job_id)
    
    if job && job.status == :started do
      job =
        job
        |> Que.Job.handle_timeout()
        |> Que.Persistence.update

      queue =
        queue
        |> Que.Queue.remove(job)
        |> Que.Queue.process

      {:noreply, queue}
    else
      # Job already completed or not found, ignore timeout
      {:noreply, queue}
    end
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

