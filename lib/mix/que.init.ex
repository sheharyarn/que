defmodule Mix.Tasks.Que.Init do
  use Mix.Task

  def run(_) do
    database =
      Que.Persistence.Mnesia.__config__
      |> Keyword.get(:database)
      |> ExUtils.Module.name

    Mix.Tasks.Amnesia.Create.run(~w|-d #{database} --disk|)
  end

end
