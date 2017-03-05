defmodule Que.Persistence do
  alias Que.Job

  @adapter Que.Persistence.Mnesia


  def find(%Job{} = job) do
  end

  def insert(%Job{} = job) do
  end

  def update(%Job{} = job) do
  end

  def destroy(%Job{} = job) do
  end

  def all do
  end

  def completed do
  end

  def incomplete do
  end

  def for_worker(worker) do
  end
end
