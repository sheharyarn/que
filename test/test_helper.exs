
## Namespace all test related modules under Que.Test

defmodule Que.Test.Meta do

  ## A TestWorker for handling Test Jobs

  defmodule TestWorker do
    require Logger
    use Que.Worker

    def perform(args) do
      Logger.debug("perform: #{inspect(args)}")
    end

    def on_success(args) do
      Logger.debug("success: #{inspect(args)}")
    end
  end


  ## Helper Module for Tests

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

