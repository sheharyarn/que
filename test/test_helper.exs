
# A TestWorker for handling Test Jobs
defmodule TestWorker do
  use Que.Worker

  def perform(args) do
    args |> inspect |> IO.puts
  end
end


# Start Tests
ExUnit.start()

