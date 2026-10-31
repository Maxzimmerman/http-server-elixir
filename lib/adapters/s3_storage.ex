defmodule S3Storage do
  alias ExAws.S3

  def upload_to_bucket do
    S3.put_object(bucket())
  end

  def process_upload(opts) do
    with {:ok, storage_path} <- storage_path(opts),
         {:ok, content_type} <- fetch_key(opts, :content_type),
         {:ok, file_binary} <- fetch_key(opts, :file_binary),
         {:ok, _response} <-
           bucket()
           |> S3.put_object(storage_path, file_binary, content_type: content_type)
           |> aws_request() do
      {:ok, storage_path}
    end
  end

  def generate_presigned_download_url(opts) do
    with {:ok, storage_path} <- fetch_key(opts, :storage_path) do
      presigned_url(:get, storage_path,
        expires_in: Keyword.get(opts, :expires_in, FileStorage.presigned_url_lifetime_seconds())
      )
    end
  end

  @impl true
  def put_object(opts) do
    with {:ok, storage_key} <- fetch_key(opts, :storage_key),
         {:ok, content_type} <- fetch_key(opts, :content_type),
         {:ok, file_binary} <- fetch_key(opts, :file_binary),
         {:ok, _response} <-
           bucket()
           |> S3.put_object(storage_key, file_binary, content_type: content_type)
           |> aws_request() do
      {:ok, storage_key}
    end
  end

  @impl true
  def delete_object(opts) do
    with {:ok, storage_key} <- fetch_key(opts, :storage_key),
         {:ok, _response} <- bucket() |> S3.delete_object(storage_key) |> aws_request() do
      {:ok, storage_key}
    end
  end

  defp storage_path(opts) do
    with {:ok, file_name} <- fetch_key(opts, :file_name),
         {:ok, owner_type} <- fetch_key(opts, :owner_type),
         {:ok, owner_id} <- fetch_key(opts, :owner_id) do
      timestamp_ms = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
      safe_file_name = String.replace(file_name, ~r/[^a-zA-Z0-9_-]/, "_")

      {:ok, "#{owner_type}_#{owner_id}/#{safe_file_name}_#{timestamp_ms}"}
    end
  end

  defp fetch_key(opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> {:ok, value}
      :error -> deprecated_error(:invalid_input, detail: "#{key} is required")
    end
  end

  defp presigned_url(http_method, storage_path, opts) do
    ExAws.Config.new(:s3, ex_aws_s3_config())
    |> S3.presigned_url(http_method, bucket(), storage_path, opts)
    |> handle_presign()
  end

  defp aws_request(operation) do
    operation
    |> ExAws.request(ex_aws_s3_config())
    |> handle_response()
  end

  defp handle_response({:ok, response}), do: {:ok, response}

  def fetch do
    S3.list_objects(bucket()) |> ExAws.request!()
  end

  defp bucket(), do: Keyword.fetch!(ex_aws_s3_config(), :bucket)

  defp ex_aws_s3_config, do: Application.fetch_env!(:ex_aws, :s3)
end
