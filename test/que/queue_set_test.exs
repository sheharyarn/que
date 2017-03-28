defmodule Que.Test.QueueSet do
  use ExUnit.Case

  alias Que.QueueSet

  test "#new returns a new QueueSet with defaults" do
    qset = QueueSet.new

    assert qset.queues == %{}
  end

end
