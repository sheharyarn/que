defmodule Que.Persistence.Mnesia do
  use Que.Persistence
  use Amnesia


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


  @config [
    db:     DB,
    table:  Jobs
  ]

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
    Amnesia.stop
    Amnesia.Schema.create(nodes)
    Amnesia.start

    # Create the DB with Disk Copies
    @db.create!(disk: nodes)
    @db.wait(15000)
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





  defdatabase DB do
    @moduledoc false

    deftable Jobs, [{:id, autoincrement}, :arguments, :worker, :status, :ref, :pid, :created_at, :updated_at],
      type:  :ordered_set do

      use Memento.Query

      @store     __MODULE__
      @moduledoc false



      @doc "Finds all Jobs"
      def all_jobs do
        # Empty Pattern - Matches all
        run_query([])
      end



      @doc "Find all Jobs for a worker"
      def all_jobs(name) do
        run_query(
          {:==, :worker, name}
        )
      end



      @doc "Find Completed Jobs"
      def completed_jobs do
        run_query(
          {:==, :status, :completed}
        )
      end



      @doc "Find Completed Jobs for worker"
      def completed_jobs(name) do
        run_query(
          {:and,
            {:==, :worker, name},
            {:==, :status, :completed}
          }
        )
      end



      @doc "Find Incomplete Jobs"
      def incomplete_jobs do
        run_query(
          {:or,
            {:==, :status, :queued},
            {:==, :status, :started}
          }
        )
      end



      @doc "Find Incomplete Jobs for worker"
      def incomplete_jobs(name) do
        run_query(
          {:and,
            {:==, :worker, name},
            {:or,
              {:==, :status, :queued},
              {:==, :status, :started}
            }
          }
        )
      end



      @doc "Find Failed Jobs"
      def failed_jobs do
        run_query(
          {:==, :status, :failed}
        )
      end



      @doc "Find Failed Jobs for worker"
      def failed_jobs(name) do
        run_query(
          {:and,
            {:==, :worker, name},
            {:==, :status, :failed}
          }
        )
      end



      @doc "Finds a Job in the DB"
      def find_job(job) do
        Amnesia.transaction do
          job
          |> normalize_id
          |> read
          |> to_que_job
        end
      end



      @doc "Inserts a new Que.Job in to DB"
      def create_job(job) do
        job
        |> Map.put(:created_at, NaiveDateTime.utc_now)
        |> update_job
      end



      @doc "Updates existing Que.Job in DB"
      def update_job(job) do
        Amnesia.transaction do
          job
          |> Map.put(:updated_at, NaiveDateTime.utc_now)
          |> to_db_job
          |> write
          |> to_que_job
        end
      end



      @doc "Deletes a Que.Job from the DB"
      def delete_job(job) do
        Amnesia.transaction do
          job
          |> normalize_id
          |> delete
        end
      end




      ## PRIVATE METHODS


      # Execute a Memento Query
      defp run_query(pattern) do
        Amnesia.transaction do
          pattern
          |> Memento.Query.query
          |> Enum.map(&to_que_job/1)
        end
      end


      # Returns Job ID
      defp normalize_id(job) do
        cond do
          is_map(job) -> job.id
          true        -> job
        end
      end



      # Convert Que.Job to Mnesia Job
      defp to_db_job(%Que.Job{} = job) do
        struct(@store, Map.from_struct(job))
      end



      # Convert Mnesia DB Job to Que.Job
      defp to_que_job(nil), do: nil
      defp to_que_job(%@store{} = job) do
        struct(Que.Job, Map.from_struct(job))
      end


    end
  end



  # Make sures that the DB exists (either
  # in memory or on disk)
  @doc false
  def initialize, do: @db.create


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
  defdelegate find(job),          to: @store,   as: :find_job

  @doc false
  defdelegate insert(job),        to: @store,   as: :create_job

  @doc false
  defdelegate update(job),        to: @store,   as: :update_job

  @doc false
  defdelegate destroy(job),       to: @store,   as: :delete_job

end
