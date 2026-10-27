defmodule Controllers.MainController do
  use ControllerDefinition

  alias Protocol.{HTTPRequest, HTTPResponse}

  @impl true
  def handle_request(%HTTPRequest{line: %{target: "/"}, close: close}) do
    {:ok, HTTPResponse.build(:ok, close: close)}
  end
end
