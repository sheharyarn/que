defmodule Que.Persistence.Mnesia do
  use Que.Persistence


  @moduledoc """
  Mnesia adapter to persist `Que.Job`s

  This module defines a Database and a Job Table in Mnesia to keep
  track of all Jobs, along with Mnesia transaction methods that
  provide an easy way to find, insert, update or destroy Jobs from
  the Database.

  It implements all callbacks defined in `Que.Persistence`, along
  with some `Mnesia` specific ones. You should read the
  `Que.Persistence` documentation if you just want to interact
  with the Jobs in database.


  ## Persisting to Disk

  `Que` works out of the box without any configuration needed, but
  initially all Jobs are not persisted to disk, and are only in
  memory. You'll need to create the Mnesia Schema on disk and create
  the Job Database for this to work.

  Que provides ways that automatically do this for you. First,
  specify the location where you want your Mnesia database to be
  created in your `config.exs` file. It's highly recommended that you
  specify your `Mix.env` in the path to keep development, test and
  production databases separate.

  ```
  config :mnesia, dir: 'mnesia/\#{Mix.env}/\#{node()}'
  # Notice the single quotes
  ```

  You can now either run the `Mix.Tasks.Que.Setup` mix task or call
  `Que.Persistence.Mnesia.setup!/0` to create the Schema, Database
  and Tables.
  """



  @config [db: DB, table: Jobs]
  @db     Module.concat(__MODULE__, @config[:db])
  @store  Module.concat(@db, @config[:table])




  @doc """
  Creates the Mnesia Database for `Que` on disk

  This creates the Schema, Database and Tables for
  Que Jobs on disk for the specified erlang nodes so
  Jobs are persisted across application restarts.
  Calling this momentarily stops the `:mnesia`
  application so you should make sure it's not being
  used when you do.

  If no argument is provided, the database is created
  for the current node.

  ## On Production

  For a compiled release (`Distillery` or `Exrm`),
  start the application in console mode or connect a
  shell to the running release and simply call the
  method:

  ```
  $ bin/my_app remote_console

  iex(my_app@127.0.0.1)1> Que.Persistence.Mnesia.setup!
  :ok
  ```

  You can alternatively provide a list of nodes for
  which you would like to create the schema:

  ```
  iex(my_app@host_x)1> nodes = [node() | Node.list]
  [:my_app@host_x, :my_app@host_y, :my_app@host_z]

  iex(my_app@node_x)2> Que.Persistence.Mnesia.setup!(nodes)
  :ok
  ```

  """
  @spec setup!(nodes :: list(node)) :: :ok
  def setup!(nodes \\ [node()]) do
    # Create the DB directory (if custom path given)
    if path = Application.get_env(:mnesia, :dir) do
      :ok = File.mkdir_p!(path)
    end

    # Create the Schema
    Memento.stop
    Memento.Schema.create(nodes)
    Memento.start

    # Create the DB with Disk Copies
    # TODO:
    # Use Memento.Table.wait when it gets implemented
    # @db.create!(disk: nodes)
    # @db.wait(15000)
    Memento.Table.create!(@store, disc_copies: nodes)
  end




  @doc "Returns the Mnesia configuration for Que"
  @spec __config__ :: Keyword.t
  def __config__ do
    [
      database: @db,
      table:    @store,
      path:     Path.expand(Application.get_env(:mnesia, :dir))
    ]
  end





  # Callbacks in Table Definition
  # -----------------------------


  # Make sures that the DB exists (either
  # in memory or on disk)
  @doc false
  def initialize do
    Memento.Table.create(@store)
  end


  @doc false
  defdelegate all,                to: @store,   as: :all_jobs

  @doc false
  defdelegate all(worker),        to: @store,   as: :all_jobs

  @doc false
  defdelegate completed,          to: @store,   as: :completed_jobs

  @doc false
  defdelegate completed(worker),  to: @store,   as: :completed_jobs

  @doc false
  defdelegate incomplete,         to: @store,   as: :incomplete_jobs

  @doc false
  defdelegate incomplete(worker), to: @store,   as: :incomplete_jobs

  @doc false
  defdelegate failed,             to: @store,   as: :failed_jobs

  @doc false
  defdelegate failed(worker),     to: @store,   as: :failed_jobs

  @doc false
  defdelegate ready_scheduled,    to: @store,   as: :ready_scheduled_jobs

  @doc false
  defdelegate ready_scheduled(worker), to: @store, as: :ready_scheduled_jobs

  @doc false
  defdelegate cancelled,          to: @store,   as: :cancelled_jobs

  @doc false
  defdelegate cancelled(worker),  to: @store,   as: :cancelled_jobs

  @doc false
  defdelegate cancellable,        to: @store,   as: :cancellable_jobs

  @doc false
  defdelegate cancellable(worker), to: @store,  as: :cancellable_jobs

  @doc false
  defdelegate retrying,           to: @store,   as: :retrying_jobs

  @doc false
  defdelegate retrying(worker),   to: @store,   as: :retrying_jobs

  @doc false
  defdelegate timeout,            to: @store,   as: :timeout_jobs

  @doc false
  defdelegate timeout(worker),    to: @store,   as: :timeout_jobs

  @doc false
  defdelegate find(job),          to: @store,   as: :find_job

  @doc false
  defdelegate insert(job),        to: @store,   as: :create_job

  @doc false
  defdelegate update(job),        to: @store,   as: :update_job

  @doc false
  defdelegate destroy(job),       to: @store,   as: :delete_job

end
