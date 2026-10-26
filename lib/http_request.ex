defmodule HTTPRequest do
  @enforce_keys [:line, :headers]
  defstruct [:line, :headers, :body, :close]

  @type t :: %__MODULE__{
          line: map(),
          headers: list(),
          body: String.t(),
          close: boolean()
        }

  @allowed_encoding_types [
    "gzip"
  ]

  def allowed_encoding_types, do: @allowed_encoding_types

  def decode_http_request(request) do
    request_list = String.split(request, "\r\n")
    [line | rest] = request_list
    {headers, [body]} = Enum.split(rest, -1)
    [method, target, version] = String.split(line, " ")

    %HTTPRequest{
      line: %{method: method, target: target, version: version},
      headers: headers,
      body: body,
      close: maybe_close_connection(headers)
    }
  end

  defp maybe_close_connection([_, "Connection: close" | _]), do: true

  defp maybe_close_connection(_request), do: false
end
