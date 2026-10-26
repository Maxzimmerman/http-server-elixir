defmodule Server do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> Client.listen() end}], strategy: :one_for_one)
  end

  # File POST endpoint
  def handle_request(%HTTPRequest{
        line: %{target: "/files" <> path},
        headers: [_, _, "Content-Type: application/octet-stream" | _],
        body: body
      }) do
    ["--directory", dir] = System.argv()

    case File.write(Path.join(dir, path), body) do
      :ok -> "HTTP/1.1 201 Created\r\n\r\n"
    end
  end

  # File GET enpoint 
  def handle_request(%HTTPRequest{line: %{target: "/files" <> path}}) do
    ["--directory", dir] = System.argv()

    case File.read(Path.join(dir, path)) do
      {:ok, binary} ->
        "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: #{byte_size(binary)}\r\n\r\n#{binary}"

      {:error, _reason} ->
        "HTTP/1.1 404 Not Found\r\n\r\n"
    end
  end

  def handle_request(_),
    do: """
    HTTP/1.1 404 Not Found\r\n\r\n
    """

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
