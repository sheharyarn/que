defmodule Que.Job do
  defstruct  [:id, :uuid, :arguments, :worker, :status, :ref, :pid]
  ## Note: Update Que.Persistence.Mnesia after changing these values


  ## Module definition for Que.Job struct to manage a Job's state.
  ## Meant for internal usage, and not for the Public API.


  @statuses [:queued, :started, :failed, :completed]
  @typedoc  "One of the atoms in `#{inspect(@statuses)}`"
  @type     status :: atom



  @doc """
  Returns a new Job struct with defaults
  """
  def new(worker, args \\ nil) do
    %Que.Job{
      uuid:       UUID.uuid4(),
      status:     :queued,
      worker:     worker,
      arguments:  args
    }
  end



  @doc """
  Update the Job status to one of the predefined values in `@statuses`
  """
  def set_status(job, status) when status in @statuses do
    %{ job | status: status }
  end



  @doc """
  Updates the Job struct with new status and spawns & monitors a new Task
  under the TaskSupervisor which executes the perform method with supplied
  arguments
  """
  def perform(job) do
    Que.Helpers.log("Starting #{job}")

    {:ok, pid} =
      Que.Helpers.do_task(fn ->
        job.worker.perform(job.arguments)
      end)

    %{ job | status: :started, pid: pid, ref: Process.monitor(pid) }
  end



  @doc """
  Handles Job Success, Calls appropriate worker method and updates the job
  status to :completed
  """
  def handle_success(job) do
    Que.Helpers.log("Completed #{job}")

    Que.Helpers.do_task(fn ->
      job.worker.on_success(job.arguments)
    end)

    %{ job | status: :completed, pid: nil, ref: nil }
  end



  @doc """
  Handles Job Failure, Calls appropriate worker method and updates the job
  status to :failed
  """
  def handle_failure(job, err) do
    Que.Helpers.log("Failed #{job}")

    Que.Helpers.do_task(fn ->
      job.worker.on_failure(job.arguments, err)
    end)

    %{ job | status: :failed, pid: nil, ref: nil }
  end
end



defimpl String.Chars, for: Que.Job do
  ## Implementing the String.Chars protocol for Que.Job structs

  def to_string(job) do
    "Job # #{job.id} with #{ExUtils.Module.name(job.worker)}"
  end
end

