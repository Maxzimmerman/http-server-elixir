defmodule Controllers.FileController do
  @behaviour ControllerDefinition

  alias Protocol.{HTTPRequest, HTTPResponse}

  @impl true
  def handle_request(%HTTPRequest{line: %{method: "POST", target: "/files" <> path}, body: body}) do
    ["--directory", dir] = System.argv()

    case File.write(Path.join(dir, path), body) do
      :ok -> {:ok, HTTPResponse.build(:created)}
    end
  end

  def handle_request(%HTTPRequest{line: %{method: "GET", target: "/files" <> path}}) do
    ["--directory", dir] = System.argv()

    case File.read(Path.join(dir, path)) do
      {:ok, binary} ->
        {:ok, HTTPResponse.build(:ok, content_type: :octet_stream, body: binary)}

      {:error, _reason} ->
        {:ok, HTTPResponse.build(:not_found)}
    end
  end
end
