defmodule Client do
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
    case :gen_tcp.recv(client, 0) do
      {:ok, content} ->
        request = Server.decode_http_request(content)
        IO.inspect(request)

        response = Server.handle_request(request)

        IO.inspect(response, label: "TEST response")

        :gen_tcp.send(client, response)

        if String.contains?(response, "Connection: close") do
          :gen_tcp.close(client)
        else
          handle_client(client)
        end

      {:error, :closed} ->
        :gen_tcp.close(client)
    end
  end
end
