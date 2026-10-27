defmodule ControllerDefinition do
  alias Protocol.HTTPRequest

  @callback handle_request(request :: %HTTPRequest{}) ::
              {:ok, binary()} | {:error, binary()}

  @doc """
  Marks a module as a controller.

  Sets the `ControllerDefinition` behaviour and appends a catch-all
  `handle_request/1` clause that replies `404 Not Found`, so each controller
  only spells out the routes it actually serves.
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour ControllerDefinition
      @before_compile ControllerDefinition
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def handle_request(_request) do
        {:error, Protocol.HTTPResponse.build(:not_found)}
      end
    end
  end
end
