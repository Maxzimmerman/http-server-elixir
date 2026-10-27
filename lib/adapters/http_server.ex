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

  defp listen_loop(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        # Spawn the worker, hand it the socket, and only then let it start.
        # `controlling_process/2` must be called by the current owner (us), and
        # the worker must not touch the socket until it owns it — otherwise its
        # `recv` could race the transfer. The `:serve` handshake enforces that.
        {:ok, pid} = Task.start(fn -> await_socket(client) end)
        :ok = :gen_tcp.controlling_process(client, pid)
        send(pid, :serve)
        listen_loop(socket)

      {:error, reason} ->
        # The listen socket is gone or unusable; stop accepting rather than
        # crash the acceptor in a tight loop. The supervisor owns recovery.
        {:error, reason}
    end
  end

  defp await_socket(client) do
    receive do
      :serve -> handle_client(client, "")
    end
  end

  # Reads until a full request is buffered, serves it, and — on keep-alive —
  # carries any leftover bytes into the next request.
  defp handle_client(client, buffer) do
    case read_request(client, buffer) do
      {:ok, request, rest} ->
        :gen_tcp.send(client, response_for(request))

        if request.close do
          :gen_tcp.close(client)
        else
          handle_client(client, rest)
        end

      {:error, :bad_request} ->
        :gen_tcp.send(client, HTTPResponse.build(:bad_request))
        :gen_tcp.close(client)

      {:error, _reason} ->
        :gen_tcp.close(client)
    end
  end

  defp read_request(client, buffer) do
    case HTTPRequest.decode_http_request(buffer) do
      {:error, :incomplete} ->
        case :gen_tcp.recv(client, 0) do
          {:ok, data} -> read_request(client, buffer <> data)
          {:error, reason} -> {:error, reason}
        end

      result ->
        result
    end
  end

  defp response_for(request) do
    case Orchestrator.delegate_request(request) do
      {:ok, response} -> response
      {:error, error_response} -> error_response
    end
  end
end
