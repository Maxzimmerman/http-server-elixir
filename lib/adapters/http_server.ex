defmodule Adapters.HTTPServer do
  @moduledoc """
  Inbound adapter: binds the listening socket, accepts connections and drives
  each one's request/response (and keep-alive) cycle. This is the system's
  entry point — bytes from the outside world arrive here and are handed to the
  `Protocol` and `Orchestrator` layers.
  """

  alias Protocol.{HTTPRequest, HTTPResponse}

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
        case HTTPRequest.decode_http_request(content) do
          {:ok, request} ->
            :gen_tcp.send(client, get_response(request))
            maybe_close_connection(client, request.close)

          {:error, :bad_request} ->
            :gen_tcp.send(client, HTTPResponse.build(:bad_request))
            :gen_tcp.close(client)
        end

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
