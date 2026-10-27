defmodule Controllers.EchoControllerTest do
  use ExUnit.Case, async: true

  alias Controllers.EchoController
  alias Protocol.{HTTPRequest, HTTPResponse}

  defp request(target, opts \\ []) do
    %HTTPRequest{
      line: %{method: "GET", target: target, version: "HTTP/1.1"},
      headers: Keyword.get(opts, :headers, %{}),
      close: Keyword.get(opts, :close, false)
    }
  end

  defp body(response) do
    [_head, body] = :binary.split(response, "\r\n\r\n")
    body
  end

  test "echoes the path segment back as a text body" do
    assert {:ok, response} = EchoController.echo(request("/echo/banana"))
    assert HTTPResponse.status_code(response) == "200"
    assert response =~ "Content-Type: text/plain"
    assert body(response) == "banana"
  end

  test "echoes an empty value for /echo/ with a trailing slash" do
    assert {:ok, response} = EchoController.echo(request("/echo/"))
    assert HTTPResponse.status_code(response) == "200"
    assert body(response) == ""
  end

  test "gzip-compresses the echo when the client accepts gzip" do
    req = request("/echo/banana", headers: %{"accept-encoding" => "gzip"})
    assert {:ok, response} = EchoController.echo(req)
    assert response =~ "Content-Encoding: gzip"
    assert :zlib.gunzip(body(response)) == "banana"
  end

  test "propagates Connection: close" do
    assert {:ok, response} = EchoController.echo(request("/echo/x", close: true))
    assert response =~ "Connection: close"
  end

  test "returns 404 for /echo with no value segment" do
    assert {:error, response} = EchoController.echo(request("/echo"))
    assert HTTPResponse.status_code(response) == "404"
  end
end
