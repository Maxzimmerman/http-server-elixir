defmodule Controllers.MainController do
  @behaviour ControllerDefinition

  def handle_request(%HTTPRequest{line: %{target: "/"}, close: true}) do
    "HTTP/1.1 200 OK\r\nConnection: close\r\n\r\n"
  end

  def handle_request(%HTTPRequest{line: %{target: "/"}}) do
    "HTTP/1.1 200 OK\r\n\r\n"
  end
end
