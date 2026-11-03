import Config

# Dummy credentials — Floci (LocalStack-style) accepts anything, but ex_aws
# still requires them to be present or it errors before making the request.
config :ex_aws,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID", "test"),
  secret_access_key: System.get_env("AWS_ACCESS_KEY", "test"),
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


# Log as Datadog-shaped JSON to stdout. In a container the Datadog Agent
# collects stdout via the Docker socket — reliable on macOS, unlike tailing a
# bind-mounted file, whose appends Docker Desktop doesn't propagate into the
# Agent container. Locally, `mix run` prints the same JSON to the terminal.
config :logger, :default_handler,
  formatter: {LoggerJSON.Formatters.Datadog, metadata: :all}
