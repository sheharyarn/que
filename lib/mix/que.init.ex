defmodule Mix.Tasks.Que.Init do
  use Mix.Task

  @shortdoc "Creates an Mnesia DB on disk for Que"


  def run(_) do
    Que.Persistence.Mnesia.setup!
  end

end
