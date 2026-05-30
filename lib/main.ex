defmodule Server do
  use Application

  @allowed_encoding_types [
    "gzip"
  ]

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> Server.listen() end}], strategy: :one_for_one)
  end

  def listen() do
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    IO.puts("Logs from your program will appear here!")

    {:ok, socket} = :gen_tcp.listen(4221, [:binary, active: false, reuseaddr: true])
    listen_loop(socket)
  end

  def listen_loop(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        {:ok, pid} = Task.start(fn -> handle_client(client) end)
        :gen_tcp.controlling_process(client, pid)
    end

    listen_loop(socket)
  end

  def handle_client(client) do
    {:ok, content} = :gen_tcp.recv(client, 0)

    request = decode_http_request(content)
    IO.inspect(request)

    response = handle_request(request)
    :gen_tcp.send(client, response)
  end

  defp handle_request(%HTTPRequest{line: %{target: "/"}}) do
    """
    HTTP/1.1 200 OK\r\n\r\n
    """
  end

  defp handle_request(%HTTPRequest{line: %{target: "/echo/" <> str}, headers: headers}) do
    [_host, "Accept-Encoding: " <> encoding | _rest] = headers
    IO.inpsect(encoding, label: "TEST")

    "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{String.length(str)}\r\n\r\n#{str}"
  end

  defp handle_request(%HTTPRequest{line: %{target: "/echo/" <> str}}) do
    "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{String.length(str)}\r\n\r\n#{str}"
  end

  defp handle_request(%HTTPRequest{line: %{target: "/user-agent"}, headers: headers}) do
    [_host, "User-Agent: " <> user_agent_value | _rest] = headers

    "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{String.length(user_agent_value)}\r\n\r\n#{user_agent_value}"
  end

  # File POST endpoint
  defp handle_request(%HTTPRequest{
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
  defp handle_request(%HTTPRequest{line: %{target: "/files" <> path}}) do
    ["--directory", dir] = System.argv()

    case File.read(Path.join(dir, path)) do
      {:ok, binary} ->
        "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: #{byte_size(binary)}\r\n\r\n#{binary}"

      {:error, _reason} ->
        "HTTP/1.1 404 Not Found\r\n\r\n"
    end
  end

  defp handle_request(_),
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
      body: body
    }
  end

  def main(_args) do
    {:ok, _pid} = Application.ensure_all_started(:codecrafters_http_server)
    Process.sleep(:infinity)
  end
end
