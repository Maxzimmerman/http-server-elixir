defmodule Controllers.FileController do
  @behaviour ControllerDefinition

  # File POST endpoint
  @impl true
  def handle_request(%HTTPRequest{
        line: %{target: "/files" <> path},
        headers: [_, _, "Content-Type: application/octet-stream" | _],
        body: body
      }) do
    ["--directory", dir] = System.argv()

    case File.write(Path.join(dir, path), body) do
      :ok -> {:ok, HTTPRequest.created()}
    end
  end

  # File GET enpoint
  def handle_request(%HTTPRequest{line: %{target: "/files" <> path}}) do
    ["--directory", dir] = System.argv()

    case File.read(Path.join(dir, path)) do
      {:ok, binary} ->
        {:ok, "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: #{byte_size(binary)}\r\n\r\n#{binary}"}

      {:error, _reason} ->
        {:ok, HTTPRequest.not_found()}
    end
  end
end
