defmodule Controllers.FilesController do
  alias Protocol.{HTTPRequest, HTTPResponse}

  defp directory,
    do:
      Application.get_env(:codecrafters_http_server, :directory) || System.get_env("DIRECTORY") ||
        "."

  def read(%HTTPRequest{line: %{target: "/files" <> path}}) do
    case File.read(Path.join(directory(), path)) do
      {:ok, binary} ->
        {:ok, HTTPResponse.build(:ok, content_type: :octet_stream, body: binary)}

      {:error, _reason} ->
        {:ok, HTTPResponse.build(:not_found)}
    end
  end

  def write(%HTTPRequest{line: %{target: "/files" <> path}, body: body}) do
    case File.write(Path.join(directory(), path), body) do
      :ok -> {:ok, HTTPResponse.build(:created)}
      {:error, _reason} -> {:error, HTTPResponse.build(:not_found)}
    end
  end
end
