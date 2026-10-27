defmodule Protocol.HTTPRequest do
  @enforce_keys [:line, :headers]
  defstruct [:line, :headers, :body, :close]

  @type request_line :: %{method: String.t(), target: String.t(), version: String.t()}

  @type headers :: %{String.t() => String.t()}

  @type t :: %__MODULE__{
          line: request_line(),
          headers: headers(),
          body: binary(),
          close: boolean()
        }

  @doc """
  Parses a raw request out of `buffer`.

  Returns `{:ok, request, rest}` where `rest` is any bytes left over after the
  request (the start of a pipelined/keep-alive follow-up). Returns
  `{:error, :incomplete}` when `buffer` doesn't yet hold a full request — the
  caller should read more bytes and try again — and `{:error, :bad_request}`
  when the request line is malformed.

  Header names are matched case-insensitively. The body is the bytes after the
  blank line, trimmed to `Content-Length`; a request whose body hasn't fully
  arrived is `:incomplete` rather than silently truncated.
  """
  @spec decode_http_request(binary()) ::
          {:ok, t(), binary()} | {:error, :incomplete | :bad_request}
  def decode_http_request(buffer) do
    case :binary.split(buffer, "\r\n\r\n") do
      [_] ->
        {:error, :incomplete}

      [head, rest] ->
        with [request_line | header_lines] <- String.split(head, "\r\n"),
             {:ok, line} <- parse_request_line(request_line) do
          headers = parse_headers(header_lines)
          take_body(line, headers, rest)
        else
          _ -> {:error, :bad_request}
        end
    end
  end

  defp parse_request_line(line) do
    case String.split(line, " ") do
      [method, target, version] -> {:ok, %{method: method, target: target, version: version}}
      _ -> :error
    end
  end

  defp parse_headers(lines) do
    Enum.reduce(lines, %{}, fn line, acc ->
      case String.split(line, ":", parts: 2) do
        [name, value] -> Map.put(acc, String.downcase(String.trim(name)), String.trim(value))
        _ -> acc
      end
    end)
  end

  defp take_body(line, headers, rest) do
    length = content_length(headers) || 0

    if byte_size(rest) < length do
      {:error, :incomplete}
    else
      <<body::binary-size(length), remainder::binary>> = rest

      {:ok,
       %__MODULE__{
         line: line,
         headers: headers,
         body: body,
         close: close_connection?(headers)
       }, remainder}
    end
  end

  defp content_length(headers) do
    with value when is_binary(value) <- header_value(headers, "Content-Length"),
         {length, ""} <- Integer.parse(value) do
      length
    else
      _ -> nil
    end
  end

  @doc "The `User-Agent` header value, or `\"\"` when absent."
  def user_agent(%__MODULE__{headers: headers}), do: header_value(headers, "User-Agent") || ""

  @doc "The encodings the client said it accepts, in request order."
  def accept_encodings(%__MODULE__{headers: headers}) do
    case header_value(headers, "Accept-Encoding") do
      nil -> []
      value -> value |> String.split(",") |> Enum.map(&String.trim/1)
    end
  end

  defp header_value(headers, name), do: Map.get(headers, String.downcase(name))

  defp close_connection?(headers) do
    case header_value(headers, "Connection") do
      nil -> false
      value -> String.downcase(value) == "close"
    end
  end
end
