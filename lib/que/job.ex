defmodule Que.Job do
  defstruct [:id, :arguments, :worker, :status, :ref, :pid]
  @statuses [:queued, :started, :failed, :completed]


  def new(worker, args) do
    %Que.Job{
      id:         UUID.uuid4(),
      status:     :queued,
      worker:     worker,
      arguments:  args
    }
  end


  def set_status(job, status) when status in @statuses do
    %{ job | status: status }
  end


  def perform(job) do
    Que.__log__("Starting #{job}")

    {:ok, pid} = Task.Supervisor.start_child(Que.TaskSupervisor, fn ->
      job.worker.perform(job.arguments)
    end)

    %{ job | status: :started, pid: pid, ref: Process.monitor(pid) }
  end


  def handle_success(job) do
    Que.__log__("Completed #{job}")

    Task.Supervisor.start_child(Que.TaskSupervisor, fn ->
      job.worker.handle_success(job.arguments)
    end)

    %{ job | status: :completed, pid: nil, ref: nil }
  end


  def handle_failure(job, err) do
    Que.__log__("Failed #{job}")

    Task.Supervisor.start_child(Que.TaskSupervisor, fn ->
      job.worker.handle_failure(job.arguments, err)
    end)

    %{ job | status: :failed, pid: nil, ref: nil }
  end
end


defimpl String.Chars, for: Que.Job do
  def to_string(job) do
    "Job # #{job.id} with #{ExUtils.Module.name(job.worker)}"
  end
end

