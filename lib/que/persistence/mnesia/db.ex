defmodule Que.Persistence.Mnesia.DB do
  @moduledoc false

  # TODO:
  # Convert this to a Memento.Collection if we add
  # more Mnesia tables




  # Memento Table Definition
  # ========================


  defmodule Jobs do
    use Memento.Table,
      attributes: [:id, :arguments, :worker, :status, :ref, :pid, :created_at, :updated_at, :scheduled_at, :retry_count, :max_retries, :last_error, :timeout, :timeout_ref, :priority],
      index: [:worker, :status, :priority],
      type: :ordered_set,
      autoincrement: true


    @moduledoc false
    @store     __MODULE__



    # Persistence Implementation
    # --------------------------


    @doc "Finds all Jobs"
    def all_jobs do
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
          {:or,
            {:==, :status, :started},
            {:==, :status, :scheduled}
          }
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
            {:or,
              {:==, :status, :started},
              {:==, :status, :scheduled}
            }
          }
        }
      )
    end


    @doc "Find ready scheduled Jobs"
    def ready_scheduled_jobs do
      current_time = NaiveDateTime.utc_now()
      run_query(
        {:and,
          {:==, :status, :scheduled},
          {:=<, :scheduled_at, current_time}
        }
      )
    end


    @doc "Find ready scheduled Jobs for worker"
    def ready_scheduled_jobs(name) do
      current_time = NaiveDateTime.utc_now()
      run_query(
        {:and,
          {:==, :worker, name},
          {:and,
            {:==, :status, :scheduled},
            {:=<, :scheduled_at, current_time}
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


    @doc "Find Cancelled Jobs"
    def cancelled_jobs do
      run_query(
        {:==, :status, :cancelled}
      )
    end


    @doc "Find Cancelled Jobs for worker"
    def cancelled_jobs(name) do
      run_query(
        {:and,
          {:==, :worker, name},
          {:==, :status, :cancelled}
        }
      )
    end


    @doc "Find Cancellable Jobs (scheduled or queued)"
    def cancellable_jobs do
      run_query(
        {:or,
          {:==, :status, :scheduled},
          {:==, :status, :queued}
        }
      )
    end


    @doc "Find Cancellable Jobs for worker"
    def cancellable_jobs(name) do
      run_query(
        {:and,
          {:==, :worker, name},
          {:or,
            {:==, :status, :scheduled},
            {:==, :status, :queued}
          }
        }
      )
    end


    @doc "Find Retrying Jobs"
    def retrying_jobs do
      run_query(
        {:==, :status, :retrying}
      )
    end


    @doc "Find Retrying Jobs for worker"
    def retrying_jobs(name) do
      run_query(
        {:and,
          {:==, :worker, name},
          {:==, :status, :retrying}
        }
      )
    end


    @doc "Find Timeout Jobs"
    def timeout_jobs do
      run_query(
        {:==, :status, :timeout}
      )
    end


    @doc "Find Timeout Jobs for worker"
    def timeout_jobs(name) do
      run_query(
        {:and,
          {:==, :worker, name},
          {:==, :status, :timeout}
        }
      )
    end



    @doc "Finds a Job in the DB"
    def find_job(job) do
      Memento.transaction! fn ->
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
      Memento.transaction! fn ->
        job
        |> Map.put(:updated_at, NaiveDateTime.utc_now)
        |> to_db_job
        |> write
        |> to_que_job
      end
    end



    @doc "Deletes a Que.Job from the DB"
    def delete_job(job) do
      Memento.transaction! fn ->
        job
        |> normalize_id
        |> delete
      end
    end




    ## PRIVATE METHODS


    # Execute a Memento Query
    defp run_query(pattern) do
      Memento.transaction! fn ->
        @store
        |> Memento.Query.select(pattern)
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


    # Read/Write/Delete to Table
    defp read(id),      do: Memento.Query.read(@store, id)
    defp delete(id),    do: Memento.Query.delete(@store, id)
    defp write(record), do: Memento.Query.write(record)

  end
end
