defmodule Que.Persistence.Mnesia do
  use Amnesia

  @db      DB
  @table   Jobs
  @store   Module.concat([__MODULE__, @db, @table])


  defdatabase DB do
    deftable Jobs, [:id, :uuid, :arguments, :worker, :status, :ref, :pid], type: :ordered_set do
      @store __MODULE__

      def create_job(job) do
        Amnesia.transaction(do: @store.write(job))
      end

    end
  end


  def insert(job) do
    @store
    |> struct(Map.from_struct(job))
    |> @store.create_job
  end
end
