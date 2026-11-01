defmodule Controllers.AWSFilesController do
  alias Protocol.{HTTPRequest, HTTPResponse}

  def read(%HTTPRequest{
        line: %{target: "/s3_files" <> path},
        headers: %{"content-type" => content_type}
      }) do
    opts = [
      storage_path: path,
      content_type: content_type
    ]

    with storage_path <- S3Storage.generate_presigned_download_url(opts) do
      {:ok, HTTPResponse.build(:ok, content_type: HTTPResponse.octet_stream_content(), body: storage_path)}
    end
  end

  def read(%HTTPRequest{}) do
    {:ok, HTTPResponse.build(:bad_request)}
  end

  def write(%HTTPRequest{
        line: %{target: "/s3_files" <> path},
        headers: %{"content-type" => content_type},
        body: body
      }) do
    opts = [
      file_name: path,
      content_type: content_type,
      file_binary: body
    ]

    with {:ok, storage_path} <- S3Storage.process_upload(opts) do
      {:ok,
       HTTPResponse.build(:ok,
         content_type: HTTPResponse.octet_stream_content(),
         body: storage_path
       )}
    end
  end
end
