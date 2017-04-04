defmodule Que.Worker do
  @doc false
  defmacro __using__(_opts) do
    quote do

      @after_compile __MODULE__

      def __after_compile__(_env, _bytecode) do
        unless Module.defines?(__MODULE__, {:perform, 1}) do
          raise Que.Error.InvalidWorker, "#{ExUtils.Module.name(__MODULE__)} must export a perform/1 method"
        end
      end


      def on_success(_arg) do
      end

      def on_failure(_arg, _err) do
      end

      def __que_worker__ do
        true
      end


      defoverridable [on_success: 1, on_failure: 2]
    end
  end

end
