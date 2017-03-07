defmodule Que.Persistence.Mnesia do
  use Amnesia

  @config [db: DB, table: Jobs]

  @db     Module.concat(__MODULE__, @config[:db])
  @store  Module.concat(@db, @config[:table])


  defdatabase DB do
    deftable Jobs, [{:id, autoincrement}, :uuid, :arguments, :worker, :status, :ref, :pid],
      type:  :ordered_set,
      index: [:uuid, :worker, :ref] do

      @store __MODULE__


      def create_job(job) do
        Amnesia.transaction do
          job
          |> to_db_job
          |> @store.write
          |> to_que_job
        end
      end

      def find_job(job) do
        Amnesia.transaction do
          job.id
          |> @store.read()
          |> to_que_job
        end
      end


      # Convert Que.Job to Mnesia Job
      defp to_db_job(%Que.Job{} = job) do
        struct(@store, Map.from_struct(job))
      end

      # Convert Mnesia Job to Que.Job
      defp to_que_job(%@store{} = job) do
        struct(Que.Job, Map.from_struct(job))
      end
    end
  end
end
