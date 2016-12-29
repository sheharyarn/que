defmodule Que.Worker do
  defmacro __using__(_opts) do
    quote do

      def perform(_arg) do
      end

      def handle_success(_arg) do
      end

      def handle_failure(_arg, _err) do
      end

      defoverridable [perform: 1, handle_success: 1, handle_failure: 2]
    end
  end
end
