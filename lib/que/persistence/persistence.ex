defmodule Que.Persistence do
  alias Que.Job

  @adapter Que.Persistence.Mnesia


  # Delegating all methods to the specified adapter

  defdelegate find(id),               to: @adapter
  defdelegate destroy(id),            to: @adapter

  defdelegate insert(job),            to: @adapter
  defdelegate update(job),            to: @adapter

  defdelegate all,                    to: @adapter
  defdelegate completed,              to: @adapter
  defdelegate incomplete,             to: @adapter

  defdelegate for_worker(worker),     to: @adapter

end
