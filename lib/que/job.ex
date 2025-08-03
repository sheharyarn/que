defmodule Que.Job do
  require Logger

  defstruct [:id, :arguments, :worker, :status, :ref, :pid, :created_at, :updated_at, :scheduled_at, :retry_count, :max_retries, :last_error, :timeout, :timeout_ref, :priority]
  ## Note: Update Que.Persistence.Mnesia after changing these values

  @moduledoc """
  Module to manage a Job's state and execute the worker's callbacks.

  Defines a `Que.Job` struct an keeps track of the Job's worker, arguments,
  status and more. Meant for internal usage, so you shouldn't use this
  unless you absolutely know what you're doing.
  """

  @statuses [:scheduled, :queued, :started, :failed, :completed, :cancelled, :retrying, :timeout]
  @typedoc "One of the atoms in `#{inspect(@statuses)}`"
  @type status :: atom

  # Priority levels - higher numbers = higher priority
  @priorities %{low: 1, normal: 5, high: 10, urgent: 20}
  @priority_levels Map.keys(@priorities)
  @typedoc "One of the atoms in `#{inspect(@priority_levels)}`"
  @type priority :: atom

  @typedoc "A `Que.Job` struct"
  @type t :: %Que.Job{}

  @doc """
  Returns a new Job struct with defaults
  """
  @spec new(worker :: Que.Worker.t(), args :: list, opts :: Keyword.t()) :: Que.Job.t()
  def new(worker, args \\ nil, opts \\ []) do
    max_retries = Keyword.get(opts, :max_retries, get_default_max_retries(worker))
    timeout = Keyword.get(opts, :timeout, get_default_timeout(worker))
    priority = get_priority_value(Keyword.get(opts, :priority, :normal))
    
    %Que.Job{
      status: :queued,
      worker: worker,
      arguments: args,
      retry_count: 0,
      max_retries: max_retries,
      timeout: timeout,
      priority: priority
    }
  end

  @doc """
  Returns a new scheduled Job struct with specified execution time
  """
  @spec new_scheduled(worker :: Que.Worker.t(), args :: list, scheduled_at :: NaiveDateTime.t(), opts :: Keyword.t()) :: Que.Job.t()
  def new_scheduled(worker, args, scheduled_at, opts \\ []) do
    max_retries = Keyword.get(opts, :max_retries, get_default_max_retries(worker))
    timeout = Keyword.get(opts, :timeout, get_default_timeout(worker))
    priority = get_priority_value(Keyword.get(opts, :priority, :normal))
    
    %Que.Job{
      status: :scheduled,
      worker: worker,
      arguments: args,
      scheduled_at: scheduled_at,
      retry_count: 0,
      max_retries: max_retries,
      timeout: timeout,
      priority: priority
    }
  end

  # Get default max retries for a worker, defaults to 3
  defp get_default_max_retries(worker) do
    if function_exported?(worker, :max_retries, 0) do
      worker.max_retries()
    else
      3
    end
  end

  # Get default timeout for a worker, defaults to 60 seconds (60000ms)
  defp get_default_timeout(worker) do
    if function_exported?(worker, :timeout, 0) do
      worker.timeout()
    else
      60_000
    end
  end

  # Convert priority atom to numeric value
  defp get_priority_value(priority) when priority in @priority_levels do
    @priorities[priority]
  end
  defp get_priority_value(priority) when is_integer(priority) do
    priority
  end
  defp get_priority_value(_), do: @priorities[:normal]

  @doc """
  Checks if the job is ready to be executed (for scheduled jobs)
  """
  @spec ready?(job :: Que.Job.t()) :: boolean
  def ready?(%Que.Job{status: :scheduled, scheduled_at: scheduled_at}) do
    NaiveDateTime.compare(NaiveDateTime.utc_now(), scheduled_at) != :lt
  end
  def ready?(%Que.Job{status: :queued}), do: true
  def ready?(_), do: false

  @doc """
  Update the Job status to one of the predefined values in `@statuses`
  """
  @spec set_status(job :: Que.Job.t(), status :: status) :: Que.Job.t()
  def set_status(job, status) when status in @statuses do
    %{job | status: status}
  end

  @doc """
  Promotes a scheduled job to queued status when it's ready to run
  """
  @spec promote_if_ready(job :: Que.Job.t()) :: Que.Job.t()
  def promote_if_ready(%Que.Job{status: :scheduled} = job) do
    if ready?(job) do
      %{job | status: :queued}
    else
      job
    end
  end  
  def promote_if_ready(job), do: job

  @doc """
  Checks if the job can be cancelled (only scheduled and queued jobs can be cancelled)
  """
  @spec cancellable?(job :: Que.Job.t()) :: boolean
  def cancellable?(%Que.Job{status: status}) when status in [:scheduled, :queued], do: true
  def cancellable?(_), do: false

  @doc """
  Cancels a job by setting its status to :cancelled
  """
  @spec cancel(job :: Que.Job.t()) :: Que.Job.t()
  def cancel(%Que.Job{} = job) do
    if cancellable?(job) do
      %{job | status: :cancelled}
    else
      job
    end
  end

  @doc """
  Checks if the job can be retried (has retries remaining)
  """
  @spec retryable?(job :: Que.Job.t()) :: boolean
  def retryable?(%Que.Job{retry_count: retry_count, max_retries: max_retries}) 
    when is_integer(retry_count) and is_integer(max_retries) do
    retry_count < max_retries
  end
  def retryable?(_), do: false

  @doc """
  Calculates the delay before the next retry using exponential backoff
  Base delay is 2^retry_count seconds with jitter
  """
  @spec retry_delay(job :: Que.Job.t()) :: integer
  def retry_delay(%Que.Job{retry_count: retry_count}) do
    base_delay = :math.pow(2, retry_count) |> round()
    jitter = :rand.uniform(1000) # 0-1000ms jitter
    (base_delay * 1000) + jitter # Convert to milliseconds
  end

  @doc """
  Schedules a job for retry with exponential backoff
  """
  @spec schedule_retry(job :: Que.Job.t(), error :: term) :: Que.Job.t()
  def schedule_retry(%Que.Job{} = job, error) do
    if retryable?(job) do
      delay_ms = retry_delay(job)
      retry_at = NaiveDateTime.add(NaiveDateTime.utc_now(), delay_ms, :millisecond)
      
      %{job | 
        status: :scheduled,
        scheduled_at: retry_at,
        retry_count: job.retry_count + 1,
        last_error: inspect(error)
      }
    else
      %{job | status: :failed, last_error: inspect(error)}
    end
  end

  @doc """
  Updates the Job struct with new status and spawns & monitors a new Task
  under the TaskSupervisor which executes the perform method with supplied
  arguments. Also sets up a timeout timer if configured.
  """
  @spec perform(job :: Que.Job.t()) :: Que.Job.t()
  def perform(job) do
    Que.Helpers.log("Starting #{job}")

    {:ok, pid} =
      Que.Helpers.do_task(fn ->
        Logger.metadata(job_id: job.id)
        job.worker.on_setup(job)
        job.worker.perform(job.arguments)
      end)

    process_ref = Process.monitor(pid)
    
    # Set timeout timer if configured
    timeout_ref = if job.timeout do
      Process.send_after(self(), {:job_timeout, job.id}, job.timeout)
    else
      nil
    end

    %{job | status: :started, pid: pid, ref: process_ref, timeout_ref: timeout_ref}
  end

  @doc """
  Handles Job timeout by killing the job process and marking it as timed out
  """
  @spec handle_timeout(job :: Que.Job.t()) :: Que.Job.t()
  def handle_timeout(job) do
    Que.Helpers.log("Timeout #{job} after #{job.timeout}ms")
    
    # Kill the job process if it's still running
    if job.pid && Process.alive?(job.pid) do
      Process.exit(job.pid, :timeout)
    end

    # Cancel the timeout timer if it exists
    if job.timeout_ref do
      Process.cancel_timer(job.timeout_ref)
    end

    # Run teardown callback
    Que.Helpers.do_task(fn ->
      Logger.metadata(job_id: job.id)
      job.worker.on_failure(job.arguments, :timeout)
      job.worker.on_teardown(job)
    end)

    %{job | status: :timeout, pid: nil, ref: nil, timeout_ref: nil}
  end

  @doc """
  Handles Job Success, Calls appropriate worker method and updates the job
  status to :completed
  """
  @spec handle_success(job :: Que.Job.t()) :: Que.Job.t()
  def handle_success(job) do
    Que.Helpers.log("Completed #{job}")

    # Cancel timeout timer if it exists
    if job.timeout_ref do
      Process.cancel_timer(job.timeout_ref)
    end

    Que.Helpers.do_task(fn ->
      Logger.metadata(job_id: job.id)
      job.worker.on_success(job.arguments)
      job.worker.on_teardown(job)
    end)

    %{job | status: :completed, pid: nil, ref: nil, timeout_ref: nil}
  end

  @doc """
  Handles Job Failure, Calls appropriate worker method and schedules retry if possible,
  otherwise updates the job status to :failed
  """
  @spec handle_failure(job :: Que.Job.t(), error :: term) :: Que.Job.t()
  def handle_failure(job, error) do
    # Cancel timeout timer if it exists
    if job.timeout_ref do
      Process.cancel_timer(job.timeout_ref)
    end

    updated_job = schedule_retry(job, error)
    
    if updated_job.status == :scheduled do
      Que.Helpers.log("Failed #{job}, retrying in #{retry_delay(job)}ms (attempt #{job.retry_count + 1}/#{job.max_retries})")
    else
      Que.Helpers.log("Failed #{job}, no more retries available")
      
      Que.Helpers.do_task(fn ->
        Logger.metadata(job_id: job.id)
        job.worker.on_failure(job.arguments, error)
        job.worker.on_teardown(job)
      end)
    end

    %{updated_job | pid: nil, ref: nil, timeout_ref: nil}
  end
end

## Implementing the String.Chars protocol for Que.Job structs

defimpl String.Chars, for: Que.Job do
  def to_string(job) do
    "Job # #{job.id} with #{ExUtils.Module.name(job.worker)}"
  end
end
