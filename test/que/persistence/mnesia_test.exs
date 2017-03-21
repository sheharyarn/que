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

end
