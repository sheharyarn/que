defmodule Que.Persistence do
  alias Que.Job

  @adapter Que.Persistence.Mnesia

  @methods %{
    main:   [:all, :completed, :incomplete],
    job:    [:find, :insert, :update, :destroy],
    worker: [:for_worker]
  }


  # Main Methods (No Args)
  for method <- @methods.main do
    def unquote(method)() do
      @adapter.unquote(method)()
    end
  end


  # Methods for Jobs
  for method <- @methods.job do
    def unquote(method)(%Job{} = job) do
      @adapter.unquote(method)(job)
    end
  end


  # Methods for Workers
  for method <- @methods.worker do
    def unquote(method)(worker) do
      @adapter.unquote(method)(worker)
    end
  end

end
