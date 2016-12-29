defmodule Que do
  use     Application
  require Logger

  @prefix "[Que]"

  @moduledoc """
  TODO: Add detailed usage docs about the Que package
  """


  @doc """
  Starts the Que Application (and it's Supervision Tree)
  """
  def start(_type, _args) do
    Que.Supervisor.start_link
  end


  # Logger wrapper for internal Que use. Not meant to be
  # used as part of the Public API
  @doc false
  def __log(msg) do
    Logger.debug("#{@prefix} #{msg}")
  end
end

