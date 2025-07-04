defmodule Que.Helpers do
  require Logger

  @prefix "[Que]"
  @moduledoc false

  @log_levels [low: 0, medium: 1, high: 2]
  @min_level Application.compile_env(:que, :log_level, :low)


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
    if (level_value(level) >= level_value(@min_level)) do
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



  # Convert Log Level to Integer
  defp level_value(level) when is_atom(level) do
    @log_levels[level] || 0
  end
end
