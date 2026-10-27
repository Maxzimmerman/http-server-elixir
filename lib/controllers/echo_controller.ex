defmodule Controllers.EchoController do
  @behaviour ControllerDefinition

  alias Protocol.{HTTPRequest, HTTPResponse}

  @impl true
  def handle_request(%HTTPRequest{line: %{target: "/echo/" <> str}, close: close} = request) do
    {:ok,
     HTTPResponse.build(:ok,
       content_type: :text,
       body: str,
       encodings: HTTPRequest.accept_encodings(request),
       close: close
     )}
  end
end
