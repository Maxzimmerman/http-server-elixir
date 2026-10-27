defmodule Protocol.HTTPResponse do
  @moduledoc """
  Owns everything about how a response looks on the wire: status lines, header
  names, content types, content negotiation/compression, `Content-Length` and
  the CRLF framing. Controllers describe a response by intent — a status and a
  few semantic options — and never spell a protocol literal themselves.

  Options for `build/2`:

    * `:body`         - the response body (default `""`)
    * `:content_type` - `:text` or `:octet_stream`
    * `:encodings`    - encodings the client will accept; the best supported one
                        is applied to the body
    * `:close`        - `true` to send `Connection: close`
  """

  @type status :: :ok | :created | :not_found | :bad_request

  @content_types %{
    text: "text/plain",
    octet_stream: "application/octet-stream"
  }

  @supported_encodings ["gzip"]

  @spec build(status(), keyword()) :: binary()
  def build(status, opts \\ []) do
    {body, encoding_headers} =
      negotiate_encoding(Keyword.get(opts, :body, ""), Keyword.get(opts, :encodings, []))

    headers =
      content_type_header(opts[:content_type]) ++
        encoding_headers ++
        connection_header(opts[:close]) ++
        content_length_header(body)

    lines = [status_line(status) | render_headers(headers)]

    IO.iodata_to_binary([Enum.join(lines, "\r\n"), "\r\n\r\n", body])
  end

  @doc """
  The numeric status code carried by a built response, as a string (e.g.
  `"200"`). Lets the caller report what it sent without re-deciding the status
  or reaching into the wire format itself — every response we build starts with
  `HTTP/1.1 <code> ...`.
  """
  @spec status_code(binary()) :: String.t()
  def status_code(<<"HTTP/1.1 ", code::binary-size(3), _rest::binary>>), do: code

  defp negotiate_encoding(body, requested) do
    case Enum.find(requested, &(&1 in @supported_encodings)) do
      "gzip" -> {:zlib.gzip(body), [{"Content-Encoding", "gzip"}]}
      nil -> {body, []}
    end
  end

  defp content_type_header(nil), do: []
  defp content_type_header(type), do: [{"Content-Type", Map.fetch!(@content_types, type)}]

  defp connection_header(true), do: [{"Connection", "close"}]
  defp connection_header(_), do: []

  defp content_length_header(body) do
    case IO.iodata_length(body) do
      0 -> []
      length -> [{"Content-Length", length}]
    end
  end

  defp render_headers(headers) do
    Enum.map(headers, fn {key, value} -> "#{key}: #{value}" end)
  end

  defp status_line(:ok), do: "HTTP/1.1 200 OK"
  defp status_line(:created), do: "HTTP/1.1 201 Created"
  defp status_line(:not_found), do: "HTTP/1.1 404 Not Found"
  defp status_line(:bad_request), do: "HTTP/1.1 400 Bad Request"
end
