defmodule Que.Error do
  @moduledoc false


  defmodule InvalidWorker do
    defexception [:message]
    @moduledoc false
  end


  defmodule JobNotFound do
    defexception [:message]
    @moduledoc false
  end

end

