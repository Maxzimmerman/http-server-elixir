defmodule Controllers.UserAgentControllerTest do
  use ExUnit.Case, async: true

  alias Controllers.UserAgentController
  alias Protocol.{HTTPRequest, HTTPResponse}

  defp request(headers, close \\ false) do
    %HTTPRequest{
      line: %{method: "GET", target: "/user-agent", version: "HTTP/1.1"},
      headers: headers,
      close: close
    }
  end

  defp body(response) do
    [_head, body] = :binary.split(response, "\r\n\r\n")
    body
  end

  test "returns the User-Agent header as a text body" do
    assert {:ok, response} = UserAgentController.show(request(%{"user-agent" => "curl/8.0"}))
    assert HTTPResponse.status_code(response) == "200"
    assert response =~ "Content-Type: text/plain"
    assert body(response) == "curl/8.0"
  end

  test "returns an empty body when no User-Agent was sent" do
    assert {:ok, response} = UserAgentController.show(request(%{}))
    assert body(response) == ""
  end

  test "propagates Connection: close" do
    assert {:ok, response} = UserAgentController.show(request(%{}, true))
    assert response =~ "Connection: close"
  end
end
