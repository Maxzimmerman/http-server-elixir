import Config

config :ex_aws,
  http_client: ExAws.Request.Req

config :ex_aws, :s3, bucket: System.get_env("AWS_S3_BUCKET")
