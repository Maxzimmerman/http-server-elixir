defmodule Controllers.AWSFilesController do
  alias Protocol.{HTTPRequest, HTTPResponse}

  def read(%HTTPRequest{line: %{target: "/upload" <> path}}) do
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

  defp opts(file_name, content_type) do
    [
      file_name: file_name,
      owner_type: "company",
      owner_id: "1",
      content_type: content_type,
      file_binary: "bytes"
    ]
  end
end
