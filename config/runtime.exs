import Config

# hackney is the HTTP client in your deps (mix.exs) — use its adapter.
# (The previous ExAws.Request.Req requires the `req` package, which isn't a dep.)
config :ex_aws,
  http_client: ExAws.Request.Hackney

# Only override the bucket when the env var is actually set, so the local
# default from config/config.exs (http-server-bucket) wins otherwise. Setting
# it unconditionally to System.get_env/1 wrote `nil` over the default.
if bucket = System.get_env("AWS_S3_BUCKET") do
  config :ex_aws, :s3, bucket: bucket
end
