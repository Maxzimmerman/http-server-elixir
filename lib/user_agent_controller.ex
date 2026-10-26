defmodule Controllers.UserAgentController do
  @behaviour ControllerDefinition

  def handle_request(%HTTPRequest{line: %{target: "/user-agent"}, headers: headers, close: true}) do
    res =
      Enum.reduce(headers, "", fn header, acc ->
        if String.contains?(header, "User-Agent") do
          "User-Agent: " <> user_agent_value = header
          acc <> user_agent_value
        else
          acc
        end
      end)

    "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{String.length(res)}\r\nConnection: close\r\n\r\n#{res}"
  end

  def handle_request(%HTTPRequest{line: %{target: "/user-agent"}, headers: headers}) do
    res =
      Enum.reduce(headers, "", fn header, acc ->
        if String.contains?(header, "User-Agent") do
          "User-Agent: " <> user_agent_value = header
          acc <> user_agent_value
        else
          acc
        end
      end)

    "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{String.length(res)}\r\n\r\n#{res}"
  end
end
