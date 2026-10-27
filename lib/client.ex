defmodule Client do
  def listen() do
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
        request = HTTPRequest.decode_http_request(content)
        IO.inspect(request)

        response = get_response(request)

        IO.inspect(response, label: "TEST response")

        :gen_tcp.send(client, response)

        maybe_close_connection(client, response)

      {:error, :closed} ->
        :gen_tcp.close(client)
    end
  end

  defp maybe_close_connection(client, response) do
    if String.contains?(response, "Connection: close") do
      :gen_tcp.close(client)
    else
      handle_client(client)
    end
  end

  defp get_response(request) do
    case Orchestrator.deligate_request(request) do
      {:ok, response} -> response
      {:error, error_response} -> error_response
      response -> IO.inspect(response)
    end
  end
end
