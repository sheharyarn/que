defmodule Que.Persistence.Mnesia do
  use Amnesia

  @config [db: DB, table: Jobs]

  @db     Module.concat(__MODULE__, @config[:db])
  @store  Module.concat(@db, @config[:table])


  def initialize do
    @db.create
  end


  defdatabase DB do
    deftable Jobs, [{:id, autoincrement}, :uuid, :arguments, :worker, :status, :ref, :pid],
      type:  :ordered_set,
      index: [:uuid, :worker, :ref] do

      @store __MODULE__


      @doc "Finds all Jobs"
      def find_all_jobs do
        Amnesia.transaction do
          @store.keys
          |> @store.match
          |> Amnesia.Selection.values
          |> Enum.map(&to_que_job/1)
        end
      end


      @doc "Finds a Job in the DB"
      def find_job(job) do
        Amnesia.transaction do
          job
          |> normalize_id
          |> @store.read
          |> to_que_job
        end
      end


      @doc "Inserts a new Que.Job in to DB"
      def create_job(job) do
        Amnesia.transaction do
          job
          |> to_db_job
          |> @store.write
          |> to_que_job
        end
      end


      @doc "Updates existing Que.Job in DB"
      def update_job(job) do
        create_job(job)
      end


      @doc "Deletes a Que.Job from the DB"
      def delete_job(job) do
        Amnesia.transaction do
          job
          |> normalize_id
          |> @store.delete
        end
      end



      ## PRIVATE METHODS


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


  defdelegate all,            to: @store,   as: :find_all_jobs
  defdelegate find(job),      to: @store,   as: :find_job

  defdelegate insert(job),    to: @store,   as: :create_job
  defdelegate update(job),    to: @store,   as: :update_job
  defdelegate destroy(job),   to: @store,   as: :delete_job
end