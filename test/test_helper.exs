
## Namespace all test related modules under Que.Test.Meta
## ======================================================


defmodule Que.Test.Meta do
  require Logger


  # Test workers for handling Jobs
  # ==============================

  defmodule TestWorker do
    use Que.Worker

    def perform(args), do: Logger.debug("#{__MODULE__} - perform: #{inspect(args)}")
  end


  defmodule ConcurrentWorker do
    use Que.Worker, concurrency: 4

    def perform(args), do: Logger.debug("#{__MODULE__} - perform: #{inspect(args)}")
  end


  defmodule SuccessWorker do
    use Que.Worker

    def perform(args),    do: Logger.debug("#{__MODULE__} - perform: #{inspect(args)}")
    def on_success(args), do: Logger.debug("#{__MODULE__} - success: #{inspect(args)}")
  end


  defmodule FailureWorker do
    use Que.Worker

    def perform(args) do
      Logger.debug("#{__MODULE__} - perform: #{inspect(args)}")
      raise "some error"
    end

    def on_failure(args, _err), do: Logger.debug("#{__MODULE__} - failure: #{inspect(args)}")
  end



  # Helper Module for Tests
  # =======================

  defmodule Helpers do

    # Sleeps for 2ms
    def wait(ms \\ 3) do
      :timer.sleep(ms)
    end

    # Captures IO output
    def capture_io(fun) do
      ExUnit.CaptureIO.capture_io(fun)
    end

    # Captures logged text to IO
    def capture_log(fun) do
      ExUnit.CaptureLog.capture_log(fun)
    end

    # Captures everything
    def capture_all(fun) do
      capture_io(fn ->
        IO.puts capture_log(fn -> fun |> capture_io |> IO.puts end)
      end)
    end

  end



  # App-specific helpers
  # ====================

  defmodule Helpers.App do

    # Restarts app and resets DB
    def reset do
      stop()
      Helpers.Mnesia.reset
      start()
      :ok
    end

    def start do
      Application.start(:que)
    end

    def stop do
      Helpers.capture_log(fn ->
        Application.stop(:que)
      end)
    end
  end



  # Mnesia-specific helpers
  # =======================

  defmodule Helpers.Mnesia do

    # Cleans up Mnesia DB
    def reset do
      Que.Persistence.Mnesia.DB.destroy
      Que.Persistence.Mnesia.DB.create
      :ok
    end

    # Deletes the Mnesia DB from disk and creates a fresh one in memory
    def reset! do
      Helpers.capture_log(fn ->
        Amnesia.stop
        File.rm_rf!(Que.Persistence.Mnesia.__config__[:path])
        Amnesia.start

        reset()
      end)
    end

    # Creates sample Mnesia jobs
    def create_sample_jobs do
      [
        %Que.Job{id: 1, status: :completed, worker: TestWorker    },
        %Que.Job{id: 2, status: :completed, worker: SuccessWorker },
        %Que.Job{id: 3, status: :failed,    worker: FailureWorker },
        %Que.Job{id: 4, status: :started,   worker: TestWorker    },
        %Que.Job{id: 5, status: :queued,    worker: SuccessWorker },
        %Que.Job{id: 6, status: :queued,    worker: FailureWorker }
      ] |> Enum.map(&Que.Persistence.Mnesia.insert/1)
    end
  end

end


# Skip Pending Tests
ExUnit.configure(exclude: [pending: true])

# Start Tests
ExUnit.start()

