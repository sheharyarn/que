defmodule Que.Helpers do
  require Logger

  @moduledoc false
  @prefix "[Que]"


  ## Helper Module for `Que`. Exports methods that are used in the
  ## project internally. Not meant for used as part of the Public
  ## API.



  @doc """
  Logger wrapper for internal Que use.
  """
  @spec log(message :: String.t) :: :ok
  def log(message) do
    Logger.info("#{@prefix} #{message}")
  end



  @doc """
  Off-loads tasks to custom `Que.TaskSupervisor`
  """
  @spec do_task((() -> any)) :: {:ok, pid}
  def do_task(fun) do
    Task.Supervisor.start_child(Que.TaskSupervisor, fun)
  end

end
