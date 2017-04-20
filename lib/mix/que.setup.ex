defmodule Mix.Tasks.Que.Setup do
  use Mix.Task

  @shortdoc "Creates an Mnesia DB on disk for Que"

  @moduledoc """
  Creates an Mnesia DB on disk for Que

  `Que` works out of the box without any configuration needed, but
  initially all Jobs are not persisted to disk, and are only in
  memory. You'll need to create the Mnesia Schema on disk and create
  the Job Database for this to work. This Mix Task lets you do that.

  You should first specify the database location in your `config.exs`
  file. It's highly recommended that you include `Mix.env` in the path
  to keep development, test and production databases separate.

  ```
  config :mnesia, dir: 'mnesia/\#{Mix.env}/\#{node()}'
  # Notice the single quotes
  ```


  You can now run the Mix Task:

  ```bash
  $ mix que.setup
  ```


  ## Production

  For production environments and compiled releases where `Mix` is not
  available, you should use `Que.Persistence.Mnesia.setup!/0` instead.
  You can [read about it here](Que.Persistence.Mnesia.html#setup!/0-on-production).


  ## Custom Node Name and Cookie

  If you need to specify the node name and cookie for the task, you can
  call it like this:

  ```bash
  $ elixir --name <node_name> --cookie <cookie> -S mix que.setup
  ```

  Source: [`elixir-lang-talk`](https://groups.google.com/forum/#!topic/elixir-lang-talk/nHPKnDF6Bl0)

  """




  @doc false
  def run(_) do
    Que.Persistence.Mnesia.setup!
  end

end
