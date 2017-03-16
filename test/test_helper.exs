
# A TestWorker for handling Test Jobs
defmodule TestWorker do
  use Que.Worker

  def perform(args) do
    IO.puts("perform: #{inspect(args)}")
  end

  def on_success(args) do
    IO.puts("success: #{inspect(args)}")
  end

  def on_failure(args, _err) do
    IO.puts("failure: #{inspect(args)}")
  end
end


# Start Tests
ExUnit.start()

