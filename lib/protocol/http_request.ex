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

  def decode_http_request(request) do
    request_list = String.split(request, "\r\n")
    [line | rest] = request_list
    {headers, [body]} = Enum.split(rest, -1)
    [method, target, version] = String.split(line, " ")

    %__MODULE__{
      line: %{method: method, target: target, version: version},
      headers: headers,
      body: body,
      close: maybe_close_connection(headers)
    }
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
