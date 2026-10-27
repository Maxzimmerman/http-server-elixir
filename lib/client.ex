defmodule Client do
  alias Protocol.HTTPRequest

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

        response = get_response(request)

        :gen_tcp.send(client, response)

        maybe_close_connection(client, request.close)

      {:error, :closed} ->
        :gen_tcp.close(client)
    end
  end

  defp maybe_close_connection(client, true), do: :gen_tcp.close(client)
  defp maybe_close_connection(client, _close), do: handle_client(client)

  defp get_response(request) do
    case Orchestrator.delegate_request(request) do
      {:ok, response} -> response
      {:error, error_response} -> error_response
    end
  end
end
