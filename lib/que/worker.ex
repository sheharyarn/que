defmodule Que.Worker do
  defmacro __using__(_opts) do
    quote do

      def perform(_arg) do
      end

      defoverridable [perform: 1]
    end
  end
end
