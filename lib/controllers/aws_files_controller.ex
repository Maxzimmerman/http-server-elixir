defmodule Controllers.AWSFilesController do
  alias Protocol.{HTTPRequest, HTTPResponse}

  def read(%HTTPRequest{line: %{target: "/s3_files" <> path}}) do
    with {:ok, storage_path} <- S3Storage.generate_presigned_download_url(opts(path, "", nil)) do
      IO.inspect(storage_path, label: "TEST")
      {:ok, HTTPResponse.build(:ok, content_type: "", body: storage_path)}
    end
  end

  def write(%HTTPRequest{line: %{target: "/files" <> path}, body: body}) do
    with {:ok, storage_path} <- S3Storage.process_upload(opts(path, "", body)) do
      IO.inspect(storage_path, label: "TEST")
      {:ok, HTTPResponse.build(:ok, content_type: "", body: storage_path)}
    end
  end

  defp opts(file_name, content_type, content) do
    [
      storage_path: file_name,
      owner_type: "company",
      owner_id: "1",
      content_type: content_type,
      file_binary: content
    ]
  end
end
