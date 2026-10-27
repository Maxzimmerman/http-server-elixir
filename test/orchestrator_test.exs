defmodule OrchestratorTest do
  use ExUnit.Case, async: true

  alias Protocol.{HTTPRequest, HTTPResponse}

  defp request(method, target, opts \\ []) do
    %HTTPRequest{
      line: %{method: method, target: target, version: "HTTP/1.1"},
      headers: Keyword.get(opts, :headers, %{}),
      body: Keyword.get(opts, :body, ""),
      close: Keyword.get(opts, :close, false)
    }
  end

  defp status(response), do: HTTPResponse.status_code(response)

  describe "delegate_request/1 routing" do
    test "routes GET / to the main controller" do
      assert {:ok, response} = Orchestrator.delegate_request(request("GET", "/"))
      assert status(response) == "200"
    end

    test "routes GET /echo/<value> to the echo controller" do
      assert {:ok, response} = Orchestrator.delegate_request(request("GET", "/echo/hi"))
      assert status(response) == "200"
    end

    test "routes GET /user-agent to the user-agent controller" do
      req = request("GET", "/user-agent", headers: %{"user-agent" => "x"})
      assert {:ok, response} = Orchestrator.delegate_request(req)
      assert status(response) == "200"
    end

    test "collapses deep paths to their first segment when routing" do
      assert {:ok, response} = Orchestrator.delegate_request(request("GET", "/echo/a/b/c"))
      assert status(response) == "200"
    end

    test "returns a 404 for an unknown path" do
      assert {:error, response} = Orchestrator.delegate_request(request("GET", "/nope"))
      assert status(response) == "404"
    end

    test "returns a 404 when the method does not match a known path" do
      assert {:error, response} = Orchestrator.delegate_request(request("DELETE", "/"))
      assert status(response) == "404"
    end

    test "routes the root path with an empty split cleanly" do
      # Guards the `[] -> "/"` branch of endpoint/1.
      assert {:ok, _response} = Orchestrator.delegate_request(request("GET", "/"))
    end
  end
end
