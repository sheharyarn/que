defmodule Que.Persistence.Mnesia do
  use Amnesia

  @db      DB
  @table   Jobs
  @store   Module.concat([__MODULE__, @db, @table])


  defdatabase DB do
    deftable Jobs, [:id, :arguments, :worker, :status, :ref, :pid], type: :ordered_set do

    end
  end

end
