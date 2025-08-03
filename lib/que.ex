defmodule Que do
  use Application

  @moduledoc """
  `Que` is a simple background job processing library backed by `Mnesia`.

  Que doesn't depend on any external services like Redis for persisting job
  state, instead uses the built-in erlang application
  [`mnesia`](http://erlang.org/doc/man/mnesia.html). This makes it extremely
  easy to use as you don't need to install anything other than Que itself.



  ## Installation

  First add it as a dependency in your `mix.exs` and run `mix deps.get`:

  ```
  defp deps do
    [{:que, "~> #{Que.Mixfile.project()[:version]}"}]
  end
  ```

  Then run `$ mix deps.get` and add it to your list of applications:

  ```
  def application do
    [applications: [:que]]
  end
  ```



  ## Usage

  Define a [`Worker`](Que.Worker.html) to process your jobs:

  ```
  defmodule App.Workers.ImageConverter do
    use Que.Worker

    def perform(image) do
      ImageTool.save_resized_copy!(image, :thumbnail)
      ImageTool.save_resized_copy!(image, :medium)
      ImageTool.save_resized_copy!(image, :large)
    end
  end
  ```

  You can now add jobs to be processed by the worker:

  ```
  Que.add(App.Workers.ImageConverter, some_image)
  #=> :ok
  ```

  Read the `Que.Worker` documentation for other callbacks and
  concurrency options.



  ## Persist to Disk

  By default, `Que` uses an in-memory `Mnesia` database so jobs are NOT
  persisted across application restarts. To do that, you first need to
  specify a path for your mnesia database in you `config.exs`.

  ```
  config :mnesia, dir: 'mnesia/\#{Mix.env}/\#{node()}'
  # Notice the single quotes
  ```

  You can now call the `que.setup` mix task to create the job database:

  ```bash
  $ mix que.setup
  ```

  For compiled releases, see the `Que.Persistence.Mnesia` documentation.

  """

  @doc """
  Starts the Que Application (and its Supervision Tree)
  """
  def start(_type, _args) do
    Que.Helpers.log("Booting Que", :low)
    Que.Supervisor.start_link()
  end

  @doc """
  Enqueues a Job to be processed by Que.

  Accepts the worker module name and a term to be passed to
  the worker as arguments.

  ## Example

  ```
  Que.add(App.Workers.FileDownloader, {"http://example.com/file/path.zip", "/some/local/path.zip"})
  #=> :ok

  Que.add(App.Workers.SignupMailer, to: "some@email.com", message: "Thank you for Signing up!")
  #=> :ok

  # Add a job with custom retry configuration
  Que.add(App.Workers.ImportantTask, task_data, max_retries: 5)
  #=> :ok

  # Add a high priority job with timeout
  Que.add(App.Workers.UrgentTask, urgent_data, priority: :high, timeout: 30_000)
  #=> :ok
  ```
  """
  @spec add(worker :: module, arguments :: term, opts :: Keyword.t()) :: {:ok, %Que.Job{}}
  def add(worker, arguments, opts \\ []) do
    Que.ServerSupervisor.add(worker, arguments, opts)
  end


  @doc """
  Schedules a Job to be processed by Que at a specific time.

  Accepts the worker module name, arguments to be passed to the worker,
  and the time when the job should be executed.

  ## Example

  ```
  # Schedule a job to run in 1 hour
  scheduled_time = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600, :second)
  Que.add_scheduled(App.Workers.SendReminder, user.email, scheduled_time)
  #=> {:ok, %Que.Job{}}

  # Schedule a job to run at a specific datetime
  scheduled_time = ~N[2024-12-31 23:59:59]
  Que.add_scheduled(App.Workers.NewYearGreeting, user.id, scheduled_time)
  #=> {:ok, %Que.Job{}}
  ```
  """
  @spec add_scheduled(worker :: module, arguments :: term, scheduled_at :: NaiveDateTime.t(), opts :: Keyword.t()) :: {:ok, %Que.Job{}}
  def add_scheduled(worker, arguments, scheduled_at, opts \\ []) do
    Que.ServerSupervisor.add_scheduled(worker, arguments, scheduled_at, opts)
  end


  @doc """
  Schedules a Job to be processed by Que after a specific number of seconds.

  This is a convenience function that schedules a job to run after the specified
  delay in seconds.

  ## Example

  ```
  # Schedule a job to run in 30 seconds
  Que.add_in(App.Workers.SendReminder, user.email, 30)
  #=> {:ok, %Que.Job{}}

  # Schedule a job to run in 1 hour (3600 seconds)
  Que.add_in(App.Workers.CleanupExpiredTokens, [], 3600)
  #=> {:ok, %Que.Job{}}
  ```
  """
  @spec add_in(worker :: module, arguments :: term, delay_seconds :: integer, opts :: Keyword.t()) :: {:ok, %Que.Job{}}
  def add_in(worker, arguments, delay_seconds, opts \\ []) do
    scheduled_at = NaiveDateTime.add(NaiveDateTime.utc_now(), delay_seconds, :second)
    add_scheduled(worker, arguments, scheduled_at, opts)
  end


  @doc """
  Cancels a Job by its ID.

  Only jobs with status `:scheduled` or `:queued` can be cancelled.
  Returns `:ok` if the job was successfully cancelled, or an error tuple otherwise.

  ## Example

  ```
  {:ok, job} = Que.add_scheduled(App.Workers.SendReminder, user.email, scheduled_time)
  
  # Later, cancel the job
  Que.cancel(job.id)
  #=> :ok
  ```
  """
  @spec cancel(job_id :: integer) :: :ok | {:error, :not_found} | {:error, :not_cancellable}
  def cancel(job_id) do
    case Que.Persistence.find(job_id) do
      nil -> 
        {:error, :not_found}
      job ->
        if Que.Job.cancellable?(job) do
          job
          |> Que.Job.cancel()
          |> Que.Persistence.update()
          :ok
        else
          {:error, :not_cancellable}
        end
    end
  end


  @doc """
  Cancels all cancellable jobs for a specific worker.

  Returns the number of jobs that were cancelled.

  ## Example

  ```
  cancelled_count = Que.cancel_all(App.Workers.SendReminder)
  #=> 5
  ```
  """
  @spec cancel_all(worker :: module) :: integer
  def cancel_all(worker) do
    worker
    |> Que.Persistence.cancellable()
    |> Enum.map(&Que.Job.cancel/1)
    |> Enum.map(&Que.Persistence.update/1)
    |> length()
  end


  @doc """
  Adds a high priority job to the queue.

  This is a convenience function that sets priority to :high.

  ## Example

  ```
  Que.add_high_priority(App.Workers.UrgentTask, critical_data)
  #=> {:ok, %Que.Job{}}
  ```
  """
  @spec add_high_priority(worker :: module, arguments :: term, opts :: Keyword.t()) :: {:ok, %Que.Job{}}
  def add_high_priority(worker, arguments, opts \\ []) do
    add(worker, arguments, Keyword.put(opts, :priority, :high))
  end


  @doc """
  Adds an urgent priority job to the queue.

  This is a convenience function that sets priority to :urgent.

  ## Example

  ```
  Que.add_urgent(App.Workers.CriticalTask, emergency_data)
  #=> {:ok, %Que.Job{}}
  ```
  """
  @spec add_urgent(worker :: module, arguments :: term, opts :: Keyword.t()) :: {:ok, %Que.Job{}}
  def add_urgent(worker, arguments, opts \\ []) do
    add(worker, arguments, Keyword.put(opts, :priority, :urgent))
  end
end
