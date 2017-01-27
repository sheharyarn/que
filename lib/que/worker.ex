defmodule Que.Worker do
  defmacro __using__(_opts) do
    quote do

      def perform(_arg) do
      end

      def on_success(_arg) do
      end

      def on_failure(_arg, _err) do
      end

      defoverridable [perform: 1, on_success: 1, on_failure: 2]
    end
  end
end
