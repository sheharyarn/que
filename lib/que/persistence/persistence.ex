defmodule Que.Persistence do
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
  defdelegate initialize,             to: @adapter



  # Macro so future adapters `use` this module
  defmacro __using__(_opts) do
    quote do
      @parent unquote(__MODULE__)
    end
  end

end
