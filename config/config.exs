import Config

# Credentials: ex_aws resolves these lazily at runtime, so {:system, ...}
# works even inside an escript. Set the env vars (e.g. via .envrc) at runtime.
config :ex_aws,
  access_key_id:     [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role],
  region: "ap-southeast-1"
