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
  @spec start_link(:ok) :: Supervisor.on_start()
  def start_link(_) do
    Que.Helpers.log("Booting Server Supervisor for Workers", :low)
    pid = Supervisor.start_link(@module, :ok, name: @module)

    # Resume Pending Jobs
    resume_queued_jobs()
    pid
  end

  @doc """
  Starts a `Que.Server` for the given worker
  """
  @spec start_server(worker :: Que.Worker.t()) :: Supervisor.on_start_child() | no_return
  def start_server(worker) do
    Que.Worker.validate!(worker)
    Supervisor.start_child(@module, [worker])
  end

  # If the server for the worker is running, add job to it.
  # If not, spawn a new server first and then add it.
  @doc false
  def add(worker, args) do
    unless Que.Server.exists?(worker) do
      start_server(worker)
    end

    Que.Server.add(worker, args)
  end

  @doc false
  def init(:ok) do
    children = [
      worker(Que.Server, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  # Spawn all (valid) Workers with queued jobs
  defp resume_queued_jobs do
    {valid, invalid} =
      Que.Persistence.incomplete()
      |> Enum.map(& &1.worker)
      |> Enum.uniq()
      |> Enum.split_with(&Que.Worker.valid?/1)

    # Notify user about pending jobs for Invalid Workers
    if length(invalid) > 0 do
      Que.Helpers.log("Found pending jobs for invalid workers: #{inspect(invalid)}")
    end

    # Process pending jobs for valid workers
    if length(valid) > 0 do
      Que.Helpers.log("Found pending jobs for: #{inspect(valid)}")
      Enum.map(valid, &start_server/1)
    end
  end
end
