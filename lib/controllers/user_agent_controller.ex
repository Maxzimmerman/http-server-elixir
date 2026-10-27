defmodule Controllers.UserAgentController do
  use ControllerDefinition

  alias Protocol.{HTTPRequest, HTTPResponse}

  @impl true
  def handle_request(%HTTPRequest{line: %{target: "/user-agent"}, close: close} = request) do
    {:ok, HTTPResponse.build(:ok, content_type: :text, body: HTTPRequest.user_agent(request), close: close)}
  end
end
