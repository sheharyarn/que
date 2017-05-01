defmodule Que.Test.Persistence.Mnesia do
  use ExUnit.Case

  alias Que.Job
  alias Que.Persistence.Mnesia

  alias Que.Test.Meta.Helpers
  alias Que.Test.Meta.TestWorker
  alias Que.Test.Meta.SuccessWorker
  alias Que.Test.Meta.FailureWorker


  setup do
    Helpers.Mnesia.reset
  end


  test "#setup! creates a Schema and persists the Mnesia DB to disk" do
    Helpers.Mnesia.reset!

    config  = Mnesia.__config__
    capture = Helpers.capture_io(&:mnesia.info/0)

    assert capture =~ ~r/Directory "#{config[:path]}" is NOT used/
    assert capture =~ ~r/ram_copies\s+=.+#{config[:database]}.+#{config[:table]}/s

    capture = Helpers.capture_all(fn ->
      assert :ok == Mnesia.setup!
      :mnesia.info
    end)

    assert capture =~ ~r/Directory "#{config[:path]}" is used/
    assert capture =~ ~r/disc_copies\s+=.+#{config[:database]}.+#{config[:table]}/s

    Helpers.Mnesia.reset!
  end


  test "#all/0 returns empty list when there are no jobs in DB" do
    assert Mnesia.all == []
  end


  test "#all/0 returns all jobs present in DB" do
    jobs = Helpers.Mnesia.create_sample_jobs

    assert Mnesia.all == jobs
  end


  test "#all/1 finds all jobs for a worker" do
    assert Mnesia.all == []

    [t1, s1, f1, t2, s2, f2] = Helpers.Mnesia.create_sample_jobs

    assert [t1, t2] == Mnesia.all(TestWorker)
    assert [s1, s2] == Mnesia.all(SuccessWorker)
    assert [f1, f2] == Mnesia.all(FailureWorker)
  end


  test "#completed returns only completed jobs" do
    [c1, c2 | _] = Helpers.Mnesia.create_sample_jobs

    assert Mnesia.completed == [c1, c2]
  end


  test "#incomplete returns queued and started jobs" do
    [_, _, _, s, q1, q2] = Helpers.Mnesia.create_sample_jobs

    assert Mnesia.incomplete == [s, q1, q2]
  end


  test "#failed returns only failed jobs" do
    [_, _, f | _] = Helpers.Mnesia.create_sample_jobs

    assert Mnesia.failed == [f]
  end


  test "#find gets a job by its id" do
    [_, _, _, s | _] = Helpers.Mnesia.create_sample_jobs

    assert s == Mnesia.find(4)
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

    assert [c1, c2, s, q1, q2] == Mnesia.all
  end
end
