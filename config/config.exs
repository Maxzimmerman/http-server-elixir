import Config

# Dummy credentials — Floci (LocalStack-style) accepts anything, but ex_aws
# still requires them to be present or it errors before making the request.
config :ex_aws,
  access_key_id: Sytem.get_env("AWS_ACCESS_KEY") || "test",
  secret_access_key: "test",
  region: "us-east-1"

# Point the S3 client at the local Floci endpoint instead of real AWS.
# scheme/host/port override the endpoint and give path-style URLs
# (http://localhost:4566/<bucket>/...), which is what Floci expects.
# `:bucket` is read by S3Storage.bucket/0 (lib/adapters/s3_storage.ex:9).
config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 4566,
  bucket: "http-server-bucket"
