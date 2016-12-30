defmodule Que.Handler do
  use GenServer

  @name         __MODULE__
  @moduledoc    false
  @concurrency  8



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
    state = {:queue.new, []}
    {:ok, state}
  end


  # Pushes a new Job to the queue and processes it
  def handle_call({:add_job, worker, arg}, _from, {qu, running}) do
    job   = Que.Job.new(worker, arg)
    qu    = :queue.in(job, qu)
    state = process_queue({qu, running})

    {:reply, :ok, state}
  end


  # Job was completed successfully - Does cleanup and executes the Success
  # callback on the Worker
  def handle_info({:DOWN, ref, :process, _pid, :normal}, {qu, running}) do
    job = find_job_by_ref(ref, running)
    Que.Job.handle_success(job)
    {:noreply, remove_job(job, {qu, running})}
  end


  # Job failed / crashed - Does cleanup and executes the Error callback
  def handle_info({:DOWN, ref, :process, _pid, err}, {qu, running}) do
    job = find_job_by_ref(ref, running)
    Que.Job.handle_failure(job, err)
    {:noreply, remove_job(job, {qu, running})}
  end


  # If the number of running jobs is less than the specified no. of
  # simultaneous workers, then start the next job in queue (if present)
  defp process_queue({qu, running}) when length(running) < @concurrency do
    case :queue.out(qu) do
      {:empty, qu}        -> {qu, running}
      {{:value, job}, qu} -> {qu, [Que.Job.perform(job) | running]}
    end
  end


  # If the number of running jobs are already equal to @concurrency, don't
  # do anything
  defp process_queue(state) do
    state
  end


  # Finds Job by its ref in the running tasks
  defp find_job_by_ref(ref, jobs) do
    Enum.find(jobs, fn job -> job.ref == ref end)
  end


  # Removes job from Running Tasks list, and processes the next item
  defp remove_job(job, {qu, running}) do
    process_queue({ qu, List.delete(running, job) })
  end
end

