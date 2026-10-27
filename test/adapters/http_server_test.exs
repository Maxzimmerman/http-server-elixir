defmodule Adapters.HTTPServerTest do
  # End-to-end tests that drive the real listener booted by the application.
  # async: false — they share the single process-wide socket on port 4221 and
  # some set the global :directory app env.
  use ExUnit.Case, async: false

  @port 4221
  @recv_timeout 2_000

  setup_all do
    # The application (and thus the listener) is started by `mix test`; make the
    # dependency explicit so the suite fails loudly if that ever stops.
    {:ok, _} = Application.ensure_all_started(:codecrafters_http_server)
    :ok
  end

  defp connect do
    {:ok, socket} =
      :gen_tcp.connect(~c"127.0.0.1", @port, [:binary, active: false, packet: :raw])

    socket
  end

  # Reads exactly one HTTP response (framed by Content-Length) off the socket.
  defp recv_response(socket) do
    head_and_rest = recv_until_headers(socket, "")
    [head, rest] = :binary.split(head_and_rest, "\r\n\r\n")

    [status | header_lines] = String.split(head, "\r\n")
    headers = parse_headers(header_lines)
    needed = headers |> Map.get("content-length", "0") |> String.to_integer()

    body = recv_body(socket, rest, needed)
    {status, headers, body}
  end

  defp recv_until_headers(socket, acc) do
    if String.contains?(acc, "\r\n\r\n") do
      acc
    else
      {:ok, data} = :gen_tcp.recv(socket, 0, @recv_timeout)
      recv_until_headers(socket, acc <> data)
    end
  end

  defp recv_body(socket, acc, needed) do
    if byte_size(acc) >= needed do
      binary_part(acc, 0, needed)
    else
      {:ok, data} = :gen_tcp.recv(socket, 0, @recv_timeout)
      recv_body(socket, acc <> data, needed)
    end
  end

  defp parse_headers(lines) do
    Map.new(lines, fn line ->
      [name, value] = String.split(line, ": ", parts: 2)
      {String.downcase(name), value}
    end)
  end

  test "serves GET / with a 200" do
    socket = connect()
    :ok = :gen_tcp.send(socket, "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n")

    assert {"HTTP/1.1 200 OK", _headers, ""} = recv_response(socket)
    :gen_tcp.close(socket)
  end

  test "echoes a path segment" do
    socket = connect()
    :ok = :gen_tcp.send(socket, "GET /echo/pineapple HTTP/1.1\r\nHost: x\r\n\r\n")

    assert {"HTTP/1.1 200 OK", headers, "pineapple"} = recv_response(socket)
    assert headers["content-type"] == "text/plain"
    :gen_tcp.close(socket)
  end

  test "gzip-encodes the echo body when requested" do
    socket = connect()

    :ok =
      :gen_tcp.send(
        socket,
        "GET /echo/pineapple HTTP/1.1\r\nHost: x\r\nAccept-Encoding: gzip\r\n\r\n"
      )

    assert {"HTTP/1.1 200 OK", headers, body} = recv_response(socket)
    assert headers["content-encoding"] == "gzip"
    assert :zlib.gunzip(body) == "pineapple"
    :gen_tcp.close(socket)
  end

  test "reflects the User-Agent header" do
    socket = connect()
    :ok = :gen_tcp.send(socket, "GET /user-agent HTTP/1.1\r\nUser-Agent: probe/9\r\n\r\n")

    assert {"HTTP/1.1 200 OK", _headers, "probe/9"} = recv_response(socket)
    :gen_tcp.close(socket)
  end

  test "returns 404 for an unknown route" do
    socket = connect()
    :ok = :gen_tcp.send(socket, "GET /does-not-exist HTTP/1.1\r\nHost: x\r\n\r\n")

    assert {"HTTP/1.1 404 Not Found", _headers, _body} = recv_response(socket)
    :gen_tcp.close(socket)
  end

  test "serves two requests on one keep-alive connection" do
    socket = connect()

    :ok = :gen_tcp.send(socket, "GET /echo/one HTTP/1.1\r\nHost: x\r\n\r\n")
    assert {"HTTP/1.1 200 OK", _h1, "one"} = recv_response(socket)

    :ok = :gen_tcp.send(socket, "GET /echo/two HTTP/1.1\r\nHost: x\r\n\r\n")
    assert {"HTTP/1.1 200 OK", _h2, "two"} = recv_response(socket)

    :gen_tcp.close(socket)
  end

  test "closes the connection after Connection: close" do
    socket = connect()
    :ok = :gen_tcp.send(socket, "GET / HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n")

    assert {"HTTP/1.1 200 OK", headers, _body} = recv_response(socket)
    assert headers["connection"] == "close"
    assert {:error, :closed} = :gen_tcp.recv(socket, 0, @recv_timeout)
  end

  test "responds 400 to a malformed request line" do
    socket = connect()
    :ok = :gen_tcp.send(socket, "NONSENSE\r\n\r\n")

    assert {"HTTP/1.1 400 Bad Request", _headers, _body} = recv_response(socket)
    :gen_tcp.close(socket)
  end

  test "serves an uploaded file round-trip over TCP" do
    dir = Path.join(System.tmp_dir!(), "http_server_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    previous = Application.get_env(:codecrafters_http_server, :directory)
    Application.put_env(:codecrafters_http_server, :directory, dir)

    on_exit(fn ->
      File.rm_rf!(dir)

      if previous do
        Application.put_env(:codecrafters_http_server, :directory, previous)
      else
        Application.delete_env(:codecrafters_http_server, :directory)
      end
    end)

    upload = connect()
    payload = "roundtrip-body"

    :ok =
      :gen_tcp.send(
        upload,
        "POST /files/data.bin HTTP/1.1\r\nContent-Length: #{byte_size(payload)}\r\n\r\n#{payload}"
      )

    assert {"HTTP/1.1 201 Created", _h, _b} = recv_response(upload)
    :gen_tcp.close(upload)

    download = connect()
    :ok = :gen_tcp.send(download, "GET /files/data.bin HTTP/1.1\r\nHost: x\r\n\r\n")

    assert {"HTTP/1.1 200 OK", headers, ^payload} = recv_response(download)
    assert headers["content-type"] == "application/octet-stream"
    :gen_tcp.close(download)
  end
end
