defmodule S3Storage do
  alias ExAws.S3


  def fetch do
    S3.list_objects(bucket()) |> ExAws.request!
  end

  defp bucket(), do: Keyword.fetch!(ex_aws_s3_config(), :bucket)

  defp ex_aws_s3_config, do: Application.fetch_env!(:ex_aws, :s3)
end
