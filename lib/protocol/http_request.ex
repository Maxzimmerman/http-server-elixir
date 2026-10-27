defmodule Protocol.HTTPRequest do
  @enforce_keys [:line, :headers]
  defstruct [:line, :headers, :body, :close]

  @type request_line :: %{method: String.t(), target: String.t(), version: String.t()}

  @type t :: %__MODULE__{
          line: request_line(),
          headers: [String.t()],
          body: String.t(),
          close: boolean()
        }

  @doc """
  Parses a raw request into an `HTTPRequest`.

  Returns `{:error, :bad_request}` for anything that isn't a well-formed
  request line followed by a blank-line-terminated header block. The body is
  taken from the bytes after that blank line, truncated to `Content-Length`
  when the header is present.
  """
  @spec decode_http_request(binary()) :: {:ok, t()} | {:error, :bad_request}
  def decode_http_request(request) do
    with [head, body] <- :binary.split(request, "\r\n\r\n"),
         [request_line | headers] <- String.split(head, "\r\n"),
         {:ok, line} <- parse_request_line(request_line) do
      {:ok,
       %__MODULE__{
         line: line,
         headers: headers,
         body: take_body(body, headers),
         close: maybe_close_connection(headers)
       }}
    else
      _ -> {:error, :bad_request}
    end
  end

  defp parse_request_line(line) do
    case String.split(line, " ") do
      [method, target, version] -> {:ok, %{method: method, target: target, version: version}}
      _ -> :error
    end
  end

  defp take_body(body, headers) do
    case content_length(headers) do
      nil -> body
      length -> binary_part(body, 0, min(length, byte_size(body)))
    end
  end

  defp content_length(headers) do
    with value when is_binary(value) <- header_value(headers, "Content-Length"),
         {length, ""} <- Integer.parse(String.trim(value)) do
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

  defp header_value(headers, name) do
    prefix = name <> ": "

    Enum.find_value(headers, fn header ->
      if String.starts_with?(header, prefix) do
        String.replace_prefix(header, prefix, "")
      end
    end)
  end

  defp maybe_close_connection(headers) do
    case header_value(headers, "Connection") do
      nil -> false
      value -> String.downcase(String.trim(value)) == "close"
    end
  end
end
