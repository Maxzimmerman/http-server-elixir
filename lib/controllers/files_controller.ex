defmodule Controllers.FileController do
  @behaviour ControllerDefinition

  alias Protocol.{HTTPRequest, HTTPResponse}

  # File POST endpoint
  @impl true
  def handle_request(%HTTPRequest{
        line: %{target: "/files" <> path},
        headers: [_, _, "Content-Type: application/octet-stream" | _],
        body: body
      }) do
    ["--directory", dir] = System.argv()

    case File.write(Path.join(dir, path), body) do
      :ok -> {:ok, HTTPResponse.build(:created)}
    end
  end

  # File GET endpoint
  def handle_request(%HTTPRequest{line: %{target: "/files" <> path}}) do
    ["--directory", dir] = System.argv()

    case File.read(Path.join(dir, path)) do
      {:ok, binary} ->
        {:ok, HTTPResponse.build(:ok, [{"Content-Type", "application/octet-stream"}], binary)}

      {:error, _reason} ->
        {:ok, HTTPResponse.build(:not_found)}
    end
  end
end
