defmodule Que do
  use Application

  @moduledoc """
  TODO: Add detailed usage docs about the Que package
  """


  @doc """
  Starts the Que Application (and its Supervision Tree)
  """
  def start(_type, _args) do
    Que.Supervisor.start_link
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
  ```
  """
  @spec add(worker :: module, arguments :: term) :: :ok
  defdelegate add(worker, arguments), to: Que.Handler
end

