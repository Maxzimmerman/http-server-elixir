defmodule Controllers.UserAgentController do
  @behaviour ControllerDefinition

  alias Protocol.{HTTPRequest, HTTPResponse}

  @impl true
  def handle_request(%HTTPRequest{line: %{target: "/user-agent"}, headers: headers, close: close}) do
    body = user_agent(headers)
    headers = [{"Content-Type", "text/plain"} | HTTPResponse.connection_header(close)]

    {:ok, HTTPResponse.build(:ok, headers, body)}
  end

  defp user_agent(headers) do
    Enum.find_value(headers, "", fn
      "User-Agent: " <> value -> value
      _ -> false
    end)
  end
end
