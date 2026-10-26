defmodule Controllers.EchoController do
  @behaviour ControllerDefinition

  def handle_request(%HTTPRequest{
        line: %{target: "/echo/" <> str},
        headers: [_host, "Accept-Encoding: " <> encoding | _rest],
        close: true
      }) do
    matches =
      encoding
      |> String.split(",")
      |> Enum.map(&String.trim(&1))
      |> Enum.filter(&Enum.member?(HTTPRequest.allowed_encoding_types(), &1))

    case length(matches) do
      1 ->
        [match | _] = matches
        compressed_body = :zlib.gzip(str)
        body_size = byte_size(compressed_body)
        IO.inspect(compressed_body)

        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Encoding: #{match}\r\nContent-Length: #{body_size}\r\nConnection: close\r\n#{compressed_body}"

      _ ->
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{String.length(str)}\r\nConnection: close\r\n#{str}"
    end
  end

  def handle_request(%HTTPRequest{
        line: %{target: "/echo/" <> str},
        headers: [_host, "Accept-Encoding: " <> encoding | _rest]
      }) do
    matches =
      encoding
      |> String.split(",")
      |> Enum.map(&String.trim(&1))
      |> Enum.filter(&Enum.member?(HTTPRequest.allowed_encoding_types(), &1))

    case length(matches) do
      1 ->
        [match | _] = matches
        compressed_body = :zlib.gzip(str)
        body_size = byte_size(compressed_body)
        IO.inspect(compressed_body)

        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Encoding: #{match}\r\nContent-Length: #{body_size}\r\n\r\n#{compressed_body}"

      _ ->
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{String.length(str)}\r\n\r\n#{str}"
    end
  end

  def handle_request(%HTTPRequest{line: %{target: "/echo/" <> str}}) do
    "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{String.length(str)}\r\n\r\n#{str}"
  end
end
