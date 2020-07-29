defmodule Que.Worker do
  @moduledoc """
  Defines a Worker for processing Jobs.

  The defined worker is responsible for processing passed jobs, and
  handling the job's success and failure callbacks. The defined
  worker must export a `perform/1` callback otherwise compilation
  will fail.


  ## Basic Worker

  ```
  defmodule MyApp.Workers.SignupMailer do
    use Que.Worker

    def perform(email) do
      Mailer.send_email(to: email, message: "Thank you for signing up!")
    end
  end
  ```

  You can also pattern match and use guard clauses like normal methods:

  ```
  defmodule MyApp.Workers.NotificationSender do
    use Que.Worker

    def perform(type: :like, to: user, count: count) do
      User.notify(user, "You have \#{count} new likes on your posts")
    end

    def perform(type: :message, to: user, from: sender) do
      User.notify(user, "You received a new message from \#{sender.name}")
    end

    def perform(to: user) do
      User.notify(user, "New activity on your profile")
    end
  end
  ```



  ## Concurrency

  By default, workers process one Job at a time. You can specify a custom
  value by passing the `concurrency` option.

  ```
  defmodule MyApp.Workers.PageScraper do
    use Que.Worker, concurrency: 4

    def perform(url), do: Scraper.scrape(url)
  end
  ```

  If you want all Jobs to be processed concurrently without any limit,
  you can set the concurrency option to `:infinity`. The concurrency
  option must either be a positive integer or `:infinity`, otherwise
  it will raise an error during compilation.



  ## Handle Job Success & Failure

  The worker can also export optional `on_success/1` and `on_failure/2`
  callbacks that handle appropriate cases.

  ```
  defmodule MyApp.Workers.CampaignMailer do
    use Que.Worker

    def perform({campaign, user}) do
      Mailer.send_campaign_email(campaign, user: user)
    end

    def on_success({campaign, user}) do
      CampaignReport.compile(campaign, status: :success, user: user)
    end

    def on_failure({campaign, user}, error) do
      CampaignReport.compile(campaign, status: :failed, user: user)
      Logger.debug("Campaign email to \#{user.id} failed: \#{inspect(error)}")
    end
  end
  ```



  ## Setup and Teardown

  You can similarly export optional `on_setup/1` and `on_teardown/1` callbacks
  that are respectively run before and after the job is performed (successfully
  or not). But instead of the job arguments, they pass the job struct as an
  argument which holds a lot more internal details that can be useful for custom
  features such as logging, metrics, requeuing and more.

  ```
  defmodule MyApp.Workers.VideoProcessor do
    use Que.Worker

    def on_setup(%Que.Job{} = job) do
      VideoMetrics.record(job.id, :start, process: job.pid, status: :starting)
    end

    def perform({user, video, options}) do
      User.notify(user, "Your video is processing, check back later.")
      FFMPEG.process(video.path, options)
    end

    def on_teardown(%Que.Job{} = job) do
      {user, video, _options} = job.arguments
      link = MyApp.Router.video_path(user.id, video.id)

      VideoMetrics.record(job.id, :end, status: job.status)
      User.notify(user, "We've finished processing your video. See the results.", link)
    end
  end
  ```



  ## Failed Job Retries

  Failed Jobs are NOT automatically retried. If you want a job to be
  retried when it fails, you can simply enqueue it again.

  To get a list of all failed jobs, you can call `Que.Persistence.failed/0`.
  """



  @typedoc "A valid worker module"
  @type    t :: module




  @doc """
  Checks if the specified module is a valid Que Worker

  ## Example

  ```
  defmodule MyWorker do
    use Que.Worker

    def perform(_args), do: nil
  end


  Que.Worker.valid?(MyWorker)
  # => true

  Que.Worker.valid?(SomeOtherModule)
  # => false
  ```
  """
  @spec valid?(module :: module) :: boolean
  def valid?(module) do
    try do
      module.__que_worker__
    rescue
      UndefinedFunctionError -> false
    end
  end




  @doc """
  Raises an error if the passed module is not a valid `Que.Worker`
  """
  @spec validate!(module :: module) :: :ok | no_return
  def validate!(module) do
    if Que.Worker.valid?(module) do
      :ok
    else
      raise Que.Error.InvalidWorker, "#{module  |> Module.split |> Enum.join(".")} is an Invalid Worker"
    end
  end




  @doc false
  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      @after_compile __MODULE__
      @concurrency   opts[:concurrency] || 1


      def concurrency,    do: @concurrency
      def __que_worker__, do: true



      ## Default implementations of on_success and on_failure callbacks

      def on_success(_arg) do
      end


      def on_failure(_arg, _err) do
      end


      def on_setup(_job) do
      end


      def on_teardown(_job) do
      end


      defoverridable [on_success: 1, on_failure: 2, on_setup: 1, on_teardown: 1]



      # Make sure the Worker is valid
      def __after_compile__(_env, _bytecode) do

        # Raises error if the Worker doesn't export a perform/1 method
        unless Module.defines?(__MODULE__, {:perform, 1}) do
          raise Que.Error.InvalidWorker,
            "#{__MODULE__  |> Module.split |> Enum.join(".")} must export a perform/1 method"
        end


        # Raise error if the concurrency option in invalid
        unless @concurrency == :infinity or (is_integer(@concurrency) and @concurrency > 0) do
          raise Que.Error.InvalidWorker,
            "#{__MODULE__  |> Module.split |> Enum.join(".")} has an invalid concurrency value"
        end
      end

    end
  end




  @doc """
  Main callback that processes the Job.

  This is a required callback that must be implemented by the worker.
  If the worker doesn't export `perform/1` method, compilation will
  fail. It takes one argument which is whatever that's passed to
  `Que.add`.

  You can define it like any other method, use guard clauses and also
  use pattern matching with multiple method definitions.
  """
  @callback perform(arguments :: term) :: term




  @doc """
  Optional callback that is executed when the job is processed
  successfully.
  """
  @callback on_success(arguments :: term) :: term




  @doc """
  Optional callback that is executed if an error is raised during
  job is processed (in `perform` callback)
  """
  @callback on_failure(arguments :: term, error :: tuple) :: term




  @doc """
  Optional callback that is executed before the job is started.
  """
  @callback on_setup(job :: Que.Job.t) :: term




  @doc """
  Optional callback that is executed after the job finishes,
  both on success and failure.
  """
  @callback on_teardown(job :: Que.Job.t) :: term
end
