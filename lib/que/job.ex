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
    {:ok, pid} = Task.Supervisor.start_child(Que.TaskSupervisor, fn ->
      job.worker.perform(job.arguments)
    end)

    %{ job | status: :started, pid: pid, ref: Process.monitor(pid) }
  end
end

