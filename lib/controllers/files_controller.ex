defmodule Controllers.FilesController do
  @behaviour ControllerDefinition

  alias Protocol.{HTTPRequest, HTTPResponse}

  @impl true
  def handle_request(%HTTPRequest{line: %{method: "POST", target: "/files" <> path}, body: body}) do
    case File.write(Path.join(directory(), path), body) do
      :ok -> {:ok, HTTPResponse.build(:created)}
      {:error, _reason} -> {:error, HTTPResponse.build(:not_found)}
    end
  end

  def handle_request(%HTTPRequest{line: %{method: "GET", target: "/files" <> path}}) do
    case File.read(Path.join(directory(), path)) do
      {:ok, binary} ->
        {:ok, HTTPResponse.build(:ok, content_type: :octet_stream, body: binary)}

      {:error, _reason} ->
        {:ok, HTTPResponse.build(:not_found)}
    end
  end

  def handle_request(_request), do: {:error, HTTPResponse.build(:not_found)}

  defp directory, do: Application.get_env(:codecrafters_http_server, :directory, ".")
end
