
## Namespace all test related modules under Que.Test.Meta
## ======================================================


defmodule Que.Test.Meta do
  require Logger


  # Test workers for handling Jobs
  # ==============================

  defmodule TestWorker do
    use Que.Worker

    def perform(args) do
      Logger.debug("#{__MODULE__} - perform: #{inspect(args)}")
    end
  end


  defmodule SuccessWorker do
    use Que.Worker
    import TestWorker

    def on_success(args) do
      Logger.debug("#{__MODULE__} - success: #{inspect(args)}")
    end
  end


  defmodule FailureWorker do
    use Que.Worker

    def perform do
      Logger.debug("#{__MODULE__} - perform: #{inspect(args)}")
      raise "some error"
    end

    def on_failure(args, _err) do
      Logger.debug("#{__MODULE__} - failure: #{inspect(args)}")
    end
  end



  # Helper Module for Tests
  # =======================

  defmodule Helpers do
    def capture_io(fun) do
      ExUnit.CaptureIO.capture_io(fun)
    end

    def capture_log(level \\ :debug, fun) do
      Logger.configure(level: level)
      ExUnit.CaptureIO.capture_io(:user, fn ->
        fun.()
        Logger.flush()
      end)
    after
      Logger.configure(level: :debug)
    end
  end

end


# Start Tests
ExUnit.start()

