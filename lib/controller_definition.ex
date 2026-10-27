defmodule ControllerDefinition do
  alias Protocol.HTTPRequest

  @callback handle_request(request :: %HTTPRequest{}) :: {Atom.t(), String.t()}
end
