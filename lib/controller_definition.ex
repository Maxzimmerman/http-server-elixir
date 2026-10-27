defmodule ControllerDefinition do
  alias Protocol.HTTPRequest

  @callback handle_request(request :: %HTTPRequest{}) :: String.t()
end
