defmodule Server do
  use Application

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
    args = System.argv()
    IO.inspect(args, label: "TEST ARGS")
    IO.inspect(request, label: "TEST REQUEST")

    response =
      case request do
        %HTTPRequest{line: %{target: "/"}} ->
          """
          HTTP/1.1 200 OK\r\n\r\n
          """

        %HTTPRequest{line: %{target: "/echo/" <> str}} ->
          "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{String.length(str)}\r\n\r\n#{str}"

        %HTTPRequest{line: %{target: "/user-agent"}, headers: headers} ->
          [_host, "User-Agent: " <> user_agent_value | _rest] = headers

          "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{String.length(user_agent_value)}\r\n\r\n#{user_agent_value}"

        %HTTPRequest{line: %{target: "/files" <> path}, headers: headers} ->
          case File.stat(path) do
            {:ok, stat} ->
              IO.puts("there")

            {:error, :enoent} ->
              IO.puts("not found")

            {:error, reason} ->
              IO.inspect(reason)
          end

          if length(args) > 1 do
            IO.inspect(args, label: "THERE")
          else
            IO.puts("NOT")
          end

          IO.puts(path)

        _ ->
          """
          HTTP/1.1 404 Not Found\r\n\r\n
          """
      end

    :gen_tcp.send(client, response)
  end

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
