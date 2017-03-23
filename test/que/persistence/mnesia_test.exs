defmodule Que.Test.Persistence.Mnesia do
  use ExUnit.Case

  alias Que.Job
  alias Que.Persistence.Mnesia

  alias Que.Test.Meta.Helpers
  alias Que.Test.Meta.TestWorker
  alias Que.Test.Meta.FailureWorker

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


  test "#find gets a job by its id" do
    [_, _, _, s | _] = Helpers.Mnesia.create_sample_jobs

    assert ^s = Mnesia.find(4)
  end


  test "#insert adds a job to the db" do
    assert Mnesia.all == []

    Mnesia.insert(%Job{status: :queued})
    jobs = [job] = Mnesia.all

    assert length(jobs)   == 1
    assert job.__struct__ == Job
    assert job.status     == :queued
  end


  test "#insert automatically assigns an id if not present" do
    assert Mnesia.all == []

    Mnesia.insert(%Job{status: :queued})
    [job] = Mnesia.all

    refute job.id == nil
  end


  test "#update finds and updates job by id" do
    Helpers.Mnesia.create_sample_jobs
    [_, _, f | _] = Mnesia.all

    assert f.id     == 3
    assert f.worker == FailureWorker
    assert f.status == :failed

    Mnesia.update(%{ f | status: :queued, worker: TestWorker })
    [_, _, f | _] = Mnesia.all

    assert f.id     == 3
    assert f.worker == TestWorker
    assert f.status == :queued
  end


  test "#destroy removes a job from DB" do
    assert [c1, c2, f, s, q1, q2] = Helpers.Mnesia.create_sample_jobs

    Mnesia.destroy(f)

    assert [^c1, ^c2, ^s, ^q1, ^q2] = Mnesia.all
  end
end
