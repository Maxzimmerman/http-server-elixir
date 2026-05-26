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

    IO.inspect(decode_http_request(content))

    request = decode_http_request(content)

    response =
      if request.line["target"] == "/" do
        IO.puts(request.line["target"])

        """
        HTTP/1.1 200 OK\r\n\r\n
        """
      else
        """
        HTTP/1.1 404 Not Found\r\n\r\n
        """
      end

    :gen_tcp.send(client, response)
  end

  def decode_http_request(request) do
    [line, headers | rest] = String.split(request, "\r\n")
    [method, target, version] = String.split(line)

    if is_nil(rest) do
      %HTTPRequest{
        line: %{method: method, target: target, version: version},
        headers: headers,
        body: rest
      }
    else
      %HTTPRequest{
        line: %{method: method, target: target, version: version},
        headers: headers,
        body: nil
      }
    end
  end

  def main(_args) do
    {:ok, _pid} = Application.ensure_all_started(:codecrafters_http_server)
    Process.sleep(:infinity)
  end
end
