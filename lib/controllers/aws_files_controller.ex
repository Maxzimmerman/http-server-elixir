defmodule Controllers.AWSFilesController do
  alias Protocol.{HTTPRequest, HTTPResponse}

  def read(%HTTPRequest{line: %{target: "/upload"}}) do
    case File.read(Path.join(directory(), path)) do
      {:ok, binary} ->
        {:ok, HTTPResponse.build(:ok, content_type: :octet_stream, body: binary)}

      {:error, _reason} ->
        {:ok, HTTPResponse.build(:not_found)}
    end
  end

  def write(%HTTPRequest{line: %{target: "/files"}, body: body}) do
    case File.write(Path.join(directory(), path), body) do
      :ok -> {:ok, HTTPResponse.build(:created)}
      {:error, _reason} -> {:error, HTTPResponse.build(:not_found)}
    end
  end
end
