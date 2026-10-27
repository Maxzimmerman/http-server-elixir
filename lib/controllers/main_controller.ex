defmodule Controllers.MainController do
  @behaviour ControllerDefinition

  @impl true
  def handle_request(%HTTPRequest{line: %{target: "/"}, close: true}) do
    {:ok, "HTTP/1.1 200 OK\r\nConnection: close\r\n\r\n"}
  end

  def handle_request(%HTTPRequest{line: %{target: "/"}}) do
    {:ok, "HTTP/1.1 200 OK\r\n\r\n"}
  end
end
