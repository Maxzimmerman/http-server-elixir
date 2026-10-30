defmodule Adapters.HTTPServer do
  @moduledoc """
  Inbound adapter: binds the listening socket, accepts connections and drives
  each one's request/response (and keep-alive) cycle. This is the system's
  entry point — bytes from the outside world arrive here and are handed to the
  `Protocol` and `Orchestrator` layers.
  """

  require Logger

  alias Protocol.{HTTPRequest, HTTPResponse}

  def listen() do
    # 1. Read the port from the environment, fallback to the CodeCrafters
    #    default (4221) if missing, and convert to integer. CodeCrafters does
    #    not set PORT, so the default is what the tester connects to.
    port_env = System.get_env("PORT") || "4221"
    {port, _} = Integer.parse(port_env)

    # 2. Open the socket listening on all interfaces (0.0.0.0)
    {:ok, listen_socket} =
      :gen_tcp.listen(port, [
        :binary,
        packet: :line,
        active: false,
        reuseaddr: true,
        ip: {0, 0, 0, 0}
      ])

    listen_loop(listen_socket)
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
        {micros, response} = :timer.tc(fn -> response_for(request) end)
        :gen_tcp.send(client, response)
        log_served(request, response, micros)

        if request.close do
          :gen_tcp.close(client)
        else
          handle_client(client, rest)
        end

      {:error, :bad_request} ->
        response = HTTPResponse.build(:bad_request)
        :gen_tcp.send(client, response)
        Logger.info("- - #{HTTPResponse.status_code(response)} (malformed request)")
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

  # One access-log line per served request: method, target, the status we sent,
  # the response size on the wire, and how long building the response took.
  defp log_served(%HTTPRequest{line: %{method: method, target: target}}, response, micros) do
    Logger.info(
      "#{method} #{target} #{HTTPResponse.status_code(response)} " <>
        "#{byte_size(response)}B #{Float.round(micros / 1000, 1)}ms"
    )
  end

  defp response_for(request) do
    case Orchestrator.delegate_request(request) do
      {:ok, response} -> response
      {:error, error_response} -> error_response
    end
  end
end
