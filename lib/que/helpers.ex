defmodule Que.Helpers do
  require Logger

  @moduledoc false
  @prefix "[Que]"


  ## Helper Module for `Que`. Exports methods that are used in the
  ## project internally. Not meant to be used as part of the Public
  ## API.



  @doc """
  Logger wrapper for internal Que use.

  Doesn't log messages if the specified level is `:low` and the
  enviroment is `:test`.
  """
  @spec log(message :: String.t, level :: atom) :: :ok
  def log(message, level \\ :medium) do
    unless (Mix.env == :test && level == :low) do
      Logger.info("#{@prefix} #{message}")
    end
  end



  @doc """
  Off-loads tasks to custom `Que.TaskSupervisor`
  """
  @spec do_task((() -> any)) :: {:ok, pid}
  def do_task(fun) do
    Task.Supervisor.start_child(Que.TaskSupervisor, fun)
  end

end
