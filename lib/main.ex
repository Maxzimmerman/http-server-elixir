defmodule Server do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> Server.listen() end}], strategy: :one_for_one)
  end

  def listen() do
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    IO.puts("Logs from your program will appear here!")

    # TODO: Uncomment the code below to pass the first stage
    #
    # # Since the tester restarts your program quite often, setting SO_REUSEADDR
    # # ensures that we don't run into 'Address already in use' errors
    {:ok, socket} = :gen_tcp.listen(4221, [:binary, active: false, reuseaddr: true])
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, content} = :gen_tcp.recv(client, 0)

    request = decode_http_request(content)

    response =
      case request do
        %HTTPRequest{line: %{target: "/"}} ->
          """
          HTTP/1.1 200 OK\r\n\r\n
          """

        %HTTPRequest{line: %{target: "/echo/" <> str}} ->
          "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{String.length(str)}\r\n\r\n#{str}"

        %HTTPRequest{line: %{target: "/user-agent"}, headers: headers} ->
          IO.inspect(headers)
          [_host, "User-Agent: " <> user_agent_value | _rest] = headers
          IO.puts(user_agent_value)
          IO.puts("RIGHT")

          "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{String.length(user_agent_value)}\r\n\r\n#{user_agent_value}"

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
