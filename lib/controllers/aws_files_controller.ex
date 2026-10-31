defmodule Controllers.AWSFilesController do
  alias Protocol.{HTTPRequest, HTTPResponse}

  def read(%HTTPRequest{line: %{target: "/upload" <> path}}) do
    with {:ok, storage_path} <- S3Storage.generate_presigned_download_url(opts(path, "")) do
      IO.puts(storage_path)
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
