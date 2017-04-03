defmodule Que.Handler do
  use GenServer

  @name      __MODULE__
  @moduledoc false



  def start_link do
    GenServer.start_link(@name, :ok, name: @name)
  end


  def add(worker, arg) do
    GenServer.call(@name, {:add_job, worker, arg})
  end



  ## Internal Callbacks
  ## ------------------


  # Initial State with Empty Queue and a list of currently running jobs
  def init(:ok) do
    Que.Persistence.initialize
    existing_jobs = Que.QueueSet.collect(Que.Persistence.incomplete)

    {:ok, existing_jobs}
  end


  # Pushes a new Job to the queue and processes it
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

end

