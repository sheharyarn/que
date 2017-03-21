defmodule Que.Test.Persistence.Mnesia do
  use ExUnit.Case

  alias Que.Job
  alias Que.Persistence.Mnesia
  alias Que.Test.Meta.Helpers

  setup do
    Helpers.reset_mnesia
  end


  test "#all returns empty list when there are no jobs in DB" do
    assert Mnesia.all == []
  end

  test "#all returns all jobs present in DB" do
    jobs = [a, b] = [
      %Job{id: 1, status: :queued},
      %Job{id: 2, status: :completed}
    ]

    Mnesia.insert(a)
    Mnesia.insert(b)

    assert Mnesia.all == jobs
  end

end
