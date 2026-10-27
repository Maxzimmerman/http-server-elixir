defmodule Controllers.MainController do
  @behaviour ControllerDefinition

  alias Protocol.{HTTPRequest, HTTPResponse}

  @impl true
  def handle_request(%HTTPRequest{line: %{target: "/"}, close: close}) do
    {:ok, HTTPResponse.build(:ok, close: close)}
  end

  def handle_request(_request), do: {:error, HTTPResponse.build(:not_found)}
end
