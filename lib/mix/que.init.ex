defmodule Mix.Tasks.Que.Init do
  use Mix.Task

  @shortdoc "Creates an Mnesia DB on disk for Que"


  def run(_) do
    # Get Database Name
    database =
      Que.Persistence.Mnesia.__config__
      |> Keyword.get(:database)
      |> ExUtils.Module.name


    # Create the DB directory (if custom path given)
    if path = Application.get_env(:mnesia, :dir) do
      :ok = File.mkdir_p!(path)
    end


    # Finally create the Mnesia DB on Disk
    Mix.Tasks.Amnesia.Create.run(~w|-d #{database} --disk|)
  end

end
