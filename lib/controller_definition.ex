defmodule ControllerDefinition do
  @callback handle_request(request :: %HTTPRequest{}) :: String.t()
end
