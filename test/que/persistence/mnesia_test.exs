defmodule Que.Test.Persistence.Mnesia do
  use ExUnit.Case

  alias Que.Job
  alias Que.Persistence.Mnesia
  alias Que.Test.Meta.Helpers

  setup do
    Helpers.Mnesia.reset
  end



  test "#all returns empty list when there are no jobs in DB" do
    assert Mnesia.all == []
  end


  test "#all returns all jobs present in DB" do
    jobs = Helpers.Mnesia.create_sample_jobs

    assert Mnesia.all == jobs
  end


  test "#completed returns only completed jobs" do
    [c1, c2 | _] = Helpers.Mnesia.create_sample_jobs

    assert Mnesia.completed == [c1, c2]
  end


  test "#incomplete returns all jobs not marked as completed" do
    [_, _, f, s, q1, q2] = Helpers.Mnesia.create_sample_jobs

    assert Mnesia.incomplete == [f, s, q1, q2]
  end

end
