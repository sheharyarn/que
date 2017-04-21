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
    ExUtils.Module.has_method?(module, {:__que_worker__, 0})
  end




  @doc """
  Raises an error if the passed module is not a valid `Que.Worker`
  """
  @spec validate!(module :: module) :: :ok | no_return
  def validate!(module) do
    if Que.Worker.valid?(module) do
      :ok
    else
      raise Que.Error.InvalidWorker, "#{ExUtils.Module.name(module)} is an Invalid Worker"
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


      defoverridable [on_success: 1, on_failure: 2]



      # Make sure the Worker is valid
      def __after_compile__(_env, _bytecode) do

        # Raises error if the Worker doesn't export a perform/1 method
        unless Module.defines?(__MODULE__, {:perform, 1}) do
          raise Que.Error.InvalidWorker,
            "#{ExUtils.Module.name(__MODULE__)} must export a perform/1 method"
        end


        # Raise error if the concurrency option in invalid
        unless @concurrency == :infinity or is_integer(@concurrency) do
          raise Que.Error.InvalidWorker,
            "#{ExUtils.Module.name(__MODULE__)} has an invalid concurrency value"
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

end
