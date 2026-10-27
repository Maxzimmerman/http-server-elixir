defmodule Protocol.HTTPRequestTest do
  use ExUnit.Case, async: true

  alias Protocol.HTTPRequest

  describe "decode_http_request/1" do
    test "returns :incomplete when the header terminator has not arrived" do
      assert {:error, :incomplete} = HTTPRequest.decode_http_request("GET / HTTP/1.1\r\n")
    end

    test "decodes a minimal request with no body" do
      raw = "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n"

      assert {:ok, request, ""} = HTTPRequest.decode_http_request(raw)
      assert request.line == %{method: "GET", target: "/", version: "HTTP/1.1"}
      assert request.body == ""
      assert request.close == false
    end

    test "downcases and trims header names and values" do
      raw = "GET / HTTP/1.1\r\n  User-Agent :  curl/8.0  \r\n\r\n"

      assert {:ok, request, ""} = HTTPRequest.decode_http_request(raw)
      assert request.headers == %{"user-agent" => "curl/8.0"}
    end

    test "keeps only the first colon when splitting a header value" do
      raw = "GET / HTTP/1.1\r\nHost: example.com:8080\r\n\r\n"

      assert {:ok, request, ""} = HTTPRequest.decode_http_request(raw)
      assert request.headers["host"] == "example.com:8080"
    end

    test "ignores header lines without a colon" do
      raw = "GET / HTTP/1.1\r\ngarbage-line\r\nHost: x\r\n\r\n"

      assert {:ok, request, ""} = HTTPRequest.decode_http_request(raw)
      assert request.headers == %{"host" => "x"}
    end

    test "rejects a malformed request line" do
      raw = "GET /\r\nHost: x\r\n\r\n"

      assert {:error, :bad_request} = HTTPRequest.decode_http_request(raw)
    end

    test "extracts a body of exactly Content-Length bytes" do
      raw = "POST /files/x HTTP/1.1\r\nContent-Length: 5\r\n\r\nhello"

      assert {:ok, request, ""} = HTTPRequest.decode_http_request(raw)
      assert request.body == "hello"
    end

    test "is :incomplete when the body has not fully arrived" do
      raw = "POST /files/x HTTP/1.1\r\nContent-Length: 5\r\n\r\nhel"

      assert {:error, :incomplete} = HTTPRequest.decode_http_request(raw)
    end

    test "returns trailing bytes after the body as the pipelined remainder" do
      raw = "POST /files/x HTTP/1.1\r\nContent-Length: 5\r\n\r\nhelloGET / HTTP/1.1\r\n"

      assert {:ok, request, rest} = HTTPRequest.decode_http_request(raw)
      assert request.body == "hello"
      assert rest == "GET / HTTP/1.1\r\n"
    end

    test "treats a non-integer Content-Length as no body" do
      raw = "POST / HTTP/1.1\r\nContent-Length: abc\r\n\r\nleftover"

      assert {:ok, request, "leftover"} = HTTPRequest.decode_http_request(raw)
      assert request.body == ""
    end

    test "sets close? from a case-insensitive Connection: close" do
      raw = "GET / HTTP/1.1\r\nConnection: Close\r\n\r\n"

      assert {:ok, request, ""} = HTTPRequest.decode_http_request(raw)
      assert request.close == true
    end

    test "leaves close? false for other Connection values" do
      raw = "GET / HTTP/1.1\r\nConnection: keep-alive\r\n\r\n"

      assert {:ok, request, ""} = HTTPRequest.decode_http_request(raw)
      assert request.close == false
    end
  end

  describe "user_agent/1" do
    test "returns the User-Agent value regardless of header casing" do
      {:ok, request, _} =
        HTTPRequest.decode_http_request("GET / HTTP/1.1\r\nuSeR-aGeNt: foo/1.0\r\n\r\n")

      assert HTTPRequest.user_agent(request) == "foo/1.0"
    end

    test "returns an empty string when absent" do
      {:ok, request, _} = HTTPRequest.decode_http_request("GET / HTTP/1.1\r\n\r\n")

      assert HTTPRequest.user_agent(request) == ""
    end
  end

  describe "accept_encodings/1" do
    test "splits and trims the comma-separated list in request order" do
      {:ok, request, _} =
        HTTPRequest.decode_http_request(
          "GET / HTTP/1.1\r\nAccept-Encoding: gzip,  deflate , br\r\n\r\n"
        )

      assert HTTPRequest.accept_encodings(request) == ["gzip", "deflate", "br"]
    end

    test "returns an empty list when absent" do
      {:ok, request, _} = HTTPRequest.decode_http_request("GET / HTTP/1.1\r\n\r\n")

      assert HTTPRequest.accept_encodings(request) == []
    end
  end
end
