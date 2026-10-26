defmodule Server do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> Client.listen() end}], strategy: :one_for_one)
  end

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

  def main(_args) do
    {:ok, _pid} = Application.ensure_all_started(:codecrafters_http_server)
    Process.sleep(:infinity)
  end
end
