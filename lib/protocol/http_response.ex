defmodule Protocol.HTTPResponse do
  @moduledoc """
  Owns HTTP response serialization: status lines, header framing and the CRLF
  rules. Controllers describe a response (status, headers, body); this module is
  the only place that knows how it is spelled on the wire.
  """

  @type status :: :ok | :created | :not_found
  @type header :: {String.t(), String.t() | integer()}

  @spec build(status(), [header()], iodata()) :: binary()
  def build(status, headers \\ [], body \\ "") do
    lines = [status_line(status) | render_headers(with_content_length(headers, body))]

    IO.iodata_to_binary([Enum.join(lines, "\r\n"), "\r\n\r\n", body])
  end

  @doc "Header list carrying `Connection: close` when the request asked to close."
  @spec connection_header(boolean()) :: [header()]
  def connection_header(true), do: [{"Connection", "close"}]
  def connection_header(_), do: []

  defp with_content_length(headers, body) do
    case IO.iodata_length(body) do
      0 -> headers
      length -> headers ++ [{"Content-Length", length}]
    end
  end

  defp render_headers(headers) do
    Enum.map(headers, fn {key, value} -> "#{key}: #{value}" end)
  end

  defp status_line(:ok), do: "HTTP/1.1 200 OK"
  defp status_line(:created), do: "HTTP/1.1 201 Created"
  defp status_line(:not_found), do: "HTTP/1.1 404 Not Found"
end
