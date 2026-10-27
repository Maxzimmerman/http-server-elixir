defmodule Controllers.EchoController do
  @behaviour ControllerDefinition

  alias Protocol.{HTTPRequest, HTTPResponse}

  @impl true
  def handle_request(%HTTPRequest{line: %{target: "/echo/" <> str}, headers: headers, close: close}) do
    base = [{"Content-Type", "text/plain"} | HTTPResponse.connection_header(close)]

    response =
      case gzip_encoding(headers) do
        {:ok, encoding} ->
          HTTPResponse.build(:ok, base ++ [{"Content-Encoding", encoding}], :zlib.gzip(str))

        :none ->
          HTTPResponse.build(:ok, base, str)
      end

    {:ok, response}
  end

  defp gzip_encoding(headers) do
    supported =
      headers
      |> accept_encoding()
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(&1 in HTTPRequest.allowed_encoding_types()))

    case supported do
      [encoding | _] -> {:ok, encoding}
      [] -> :none
    end
  end

  defp accept_encoding(headers) do
    Enum.find_value(headers, "", fn
      "Accept-Encoding: " <> value -> value
      _ -> false
    end)
  end
end
