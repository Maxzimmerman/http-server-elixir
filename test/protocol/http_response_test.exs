defmodule Protocol.HTTPResponseTest do
  use ExUnit.Case, async: true

  alias Protocol.HTTPResponse

  # Splits a built response into {status_line, headers_map, body}.
  defp parse(response) do
    [head, body] = :binary.split(response, "\r\n\r\n")
    [status | header_lines] = String.split(head, "\r\n")

    headers =
      Map.new(header_lines, fn line ->
        [name, value] = String.split(line, ": ", parts: 2)
        {name, value}
      end)

    {status, headers, body}
  end

  describe "build/2" do
    test "a bare 200 has no headers and no body" do
      assert HTTPResponse.build(:ok) == "HTTP/1.1 200 OK\r\n\r\n"
    end

    test "maps each known status to its status line" do
      assert {"HTTP/1.1 200 OK", _, _} = parse(HTTPResponse.build(:ok))
      assert {"HTTP/1.1 201 Created", _, _} = parse(HTTPResponse.build(:created))
      assert {"HTTP/1.1 404 Not Found", _, _} = parse(HTTPResponse.build(:not_found))
      assert {"HTTP/1.1 400 Bad Request", _, _} = parse(HTTPResponse.build(:bad_request))
    end

    test "writes Content-Type and Content-Length for a text body" do
      {_status, headers, body} =
        parse(HTTPResponse.build(:ok, content_type: :text, body: "abc"))

      assert headers["Content-Type"] == "text/plain"
      assert headers["Content-Length"] == "3"
      assert body == "abc"
    end

    test "uses application/octet-stream for the octet_stream type" do
      {_status, headers, _body} =
        parse(HTTPResponse.build(:ok, content_type: :octet_stream, body: "xx"))

      assert headers["Content-Type"] == "application/octet-stream"
    end

    test "omits Content-Length when the body is empty" do
      {_status, headers, _body} = parse(HTTPResponse.build(:ok, content_type: :text))

      refute Map.has_key?(headers, "Content-Length")
    end

    test "emits Connection: close when asked" do
      {_status, headers, _body} = parse(HTTPResponse.build(:ok, close: true))

      assert headers["Connection"] == "close"
    end

    test "omits Connection when close is not set" do
      {_status, headers, _body} = parse(HTTPResponse.build(:ok, close: false))

      refute Map.has_key?(headers, "Connection")
    end

    test "gzip-compresses the body and advertises the encoding when gzip is accepted" do
      {_status, headers, body} =
        parse(HTTPResponse.build(:ok, content_type: :text, body: "abc", encodings: ["gzip"]))

      assert headers["Content-Encoding"] == "gzip"
      assert :zlib.gunzip(body) == "abc"
      assert headers["Content-Length"] == Integer.to_string(byte_size(body))
    end

    test "picks gzip even when it is not the first accepted encoding" do
      {_status, headers, _body} =
        parse(
          HTTPResponse.build(:ok, content_type: :text, body: "abc", encodings: ["br", "gzip"])
        )

      assert headers["Content-Encoding"] == "gzip"
    end

    test "leaves the body untouched when no accepted encoding is supported" do
      {_status, headers, body} =
        parse(HTTPResponse.build(:ok, content_type: :text, body: "abc", encodings: ["br"]))

      refute Map.has_key?(headers, "Content-Encoding")
      assert body == "abc"
    end
  end

  describe "status_code/1" do
    test "reads the numeric code out of a built response" do
      assert HTTPResponse.status_code(HTTPResponse.build(:ok)) == "200"
      assert HTTPResponse.status_code(HTTPResponse.build(:created)) == "201"
      assert HTTPResponse.status_code(HTTPResponse.build(:not_found)) == "404"
    end
  end
end
