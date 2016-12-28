defmodule Que do
  use Application

  @moduledoc """
  TODO: Add detailed usage docs about the Que package
  """

  @doc """
  Starts the Que Application (and it's Supervision Tree)
  """
  def start(_type, _args) do
    Que.Supervisor.start_link
  end
end

