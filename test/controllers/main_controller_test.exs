defmodule Controllers.MainControllerTest do
  use ExUnit.Case, async: true

  alias Controllers.MainController
  alias Protocol.{HTTPRequest, HTTPResponse}

  defp request(close), do: %HTTPRequest{line: %{}, headers: %{}, close: close}

  test "responds 200 with an empty body" do
    assert {:ok, response} = MainController.index(request(false))
    assert HTTPResponse.status_code(response) == "200"
    assert response == "HTTP/1.1 200 OK\r\n\r\n"
  end

  test "propagates Connection: close" do
    assert {:ok, response} = MainController.index(request(true))
    assert response =~ "Connection: close"
  end
end
