defmodule ControllerDefinition do
  alias Protocol.HTTPRequest

  @callback handle_request(request :: %HTTPRequest{}) ::
              {:ok, binary()} | {:error, binary()}
end
