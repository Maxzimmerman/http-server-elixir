import Config

# config.exs
config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9000

config :ex_aws,
  http_client: ExAws.Request.Req

config :ex_aws, :s3, bucket: System.get_env("AWS_S3_BUCKET")
