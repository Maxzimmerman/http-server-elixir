[![progress-banner](https://backend.codecrafters.io/progress/http-server/73c631d7-6e0b-4405-bc34-adad8a2e1fbc)](https://app.codecrafters.io/users/codecrafters-bot?r=2qF)

This is a starting point for Elixir solutions to the
["Build Your Own HTTP server" Challenge](https://app.codecrafters.io/courses/http-server/overview).

[HTTP](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol) is the
protocol that powers the web. In this challenge, you'll build a HTTP/1.1 server
that is capable of serving multiple clients.

Along the way you'll learn about TCP servers,
[HTTP request syntax](https://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html),
and more.

**Note**: If you're viewing this repo on GitHub, head over to
[codecrafters.io](https://codecrafters.io) to try the challenge.

# Passing the first stage

The entry point for your HTTP server implementation is in `lib/main.ex`. Study
and uncomment the relevant code, and then run the command below to execute the
tests on our servers:

```sh
codecrafters submit
```

Time to move on to the next stage!

# Stage 2 & beyond

Note: This section is for stages 2 and beyond.

1. Ensure you have `mix` installed locally
1. Run `./your_program.sh` to run your program, which is implemented in
   `lib/main.ex`.
1. Run `codecrafters submit` to submit your solution to CodeCrafters. Test
   output will be streamed to your terminal.

# Running it yourself

`codecrafters submit` runs the test suite against your server on CodeCrafters'
infrastructure. To hit the endpoints yourself, run the server locally and make
requests with `curl` (or any HTTP client).

Start the server (listens on port `4221`):

```sh
./your_program.sh
```

The `/files` endpoint reads and writes from a directory passed via the
`--directory` flag (defaults to the current directory if omitted):

```sh
./your_program.sh --directory /tmp/
```

Then, from another terminal:

```sh
# Echo endpoint — responds with the path segment as the body
curl -v http://localhost:4000/echo/hello

# User-Agent endpoint — responds with the User-Agent header value
curl -v -H "User-Agent: foobar/1.2.3" http://localhost:4000/user-agent

# Files endpoint (GET) — reads a file from --directory
echo -n "file contents here" > /tmp/foo.txt
curl -v http://localhost:4000/files/foo.txt

# Files endpoint (POST) — writes a file into --directory
curl -v --data "12345" -H "Content-Type: application/octet-stream" \
  http://localhost:4000/files/newfile.txt

# Connection: close — the server echoes a `Connection: close` response header
# and closes the connection after responding
curl -v -H "Connection: close" http://localhost:4000/echo/hello

UPLOAD
curl -v --data "12345" \
  -H "Connection: close" \
  -H "Content-Type: application/octet-stream" \
  http://localhost:4000/s3_files/a.txt

DOWNLOAD
curl -v -H "Connection: close" \
  -H "Content-Type: application/octet-stream" \
  http://localhost:4000/s3_files/foo.txt 

DELETE

curl -X DELETE http://localhost:4000/s3_files/a.txt \
  -H "Content-Type: application/octet-stream"
```

DOCKER

```
create image 
docker build -t http-server .

run container with image

docker run --rm -e PORT=4000 -p 4000:4000 http-server
```

Use `curl -v` to inspect the status line and headers (`Content-Type`,
`Content-Length`, etc.), which is what most stages are tested on.


# Observability — metrics + logs to Datadog

The server ships two signals to Datadog, both built on the `:telemetry` event
`[:web, :request, :done]` that `Adapters.HTTPServer` emits once per served
request (measurement `duration`; metadata `method` / `path` / `status`):

- **Metrics** — `Telemetry.Reporter` runs `TelemetryMetricsStatsd` (DogStatsD,
  `:datadog` format) and forwards two metrics, tagged by `method` + `status`:
  - `web.request.done.count` — request count
  - `web.request.done.duration` — response-build latency (ms) distribution
- **Logs** — `Telemetry.Handler` logs one structured line per request; the
  `LoggerJSON.Formatters.Datadog` formatter writes it as JSON to **stdout**. The
  app runs as a container and the Datadog Agent collects its stdout via the
  Docker socket. Searchable fields: `status`, `method`, `path`, `duration_ms`.

Nothing talks to Datadog's API directly — the app sends to a local **Datadog
Agent** (DogStatsD UDP for metrics, Docker-socket stdout collection for logs)
and the Agent forwards. App and Agent share a user-defined Docker network
(`dd-net`) so the app can reach the Agent by name for metrics.

## Dependencies (already in `mix.exs`)

```elixir
{:telemetry_metrics, "~> 1.0"},
{:telemetry_metrics_statsd, "~> 0.7"},   # metrics → DogStatsD
{:logger_json, "~> 7.0"},                # Datadog JSON log formatter
{:jason, "~> 1.4"}                        # encoder logger_json needs (not Poison)
```

## Logger config (already in `config/config.exs`)

```elixir
# Log Datadog-shaped JSON to stdout; the Agent collects container stdout via
# the Docker socket (reliable on macOS, unlike tailing a bind-mounted file).
config :logger, :default_handler,
  formatter: {LoggerJSON.Formatters.Datadog, metadata: :all}
```

## Why the app runs as a container

On Docker Desktop for Mac the Agent **can't reliably tail a bind-mounted log
file** — the VM file-sharing layer doesn't propagate appends into the Agent
container (it reads the file once and never sees it grow). So the app runs as a
container and the Agent collects its **stdout** through the Docker socket. App
and Agent share a user-defined network (`dd-net`) so metrics (DogStatsD UDP) can
reach the Agent by name.

## 1. Build the image and create the network

```sh
docker network create dd-net
docker build --ulimit nofile=65536:65536 -t http-server:latest .
```

## 2. Run the Datadog Agent

Get a Datadog **API key** (Organization Settings → API Keys). Non-obvious flags:

- `DD_SITE=ap2.datadoghq.com` — must match your account's region; a key sent to
  the wrong site 403s with "API key is missing or invalid".
- `DD_HOSTNAME` — the Agent can't derive a hostname on Docker Desktop and exits
  without it.
- `DD_DOGSTATSD_NON_LOCAL_TRAFFIC=true` — accept DogStatsD from the app container.
- the Docker socket mount is how the Agent reads container stdout.
  `container_collect_all` is left **off**, so only containers carrying a
  `com.datadoghq.ad.logs` label are collected (just the app) — not every
  container on the machine.

```sh
docker run -d --name dd-agent \
  --network dd-net \
  -e DD_API_KEY=<your-datadog-api-key> \
  -e DD_SITE=ap2.datadoghq.com \
  -e DD_HOSTNAME=codecrafters-dev \
  -e DD_DOGSTATSD_NON_LOCAL_TRAFFIC=true \
  -e DD_APM_ENABLED=false \
  -e DD_LOGS_ENABLED=true \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  gcr.io/datadoghq/agent:7
```

## 3. Run the app container

`DD_AGENT_HOST=dd-agent` points the metrics reporter at the Agent over `dd-net`;
the `com.datadoghq.ad.logs` label tells the Agent to collect this container's
stdout and tags it with the service/source.

```sh
docker run -d --name http-server \
  --network dd-net \
  -e PORT=4221 \
  -e DD_AGENT_HOST=dd-agent \
  -e DD_DOGSTATSD_PORT=8125 \
  -p 4221:4221 \
  -l 'com.datadoghq.ad.logs=[{"source":"elixir","service":"codecrafters-http-server"}]' \
  http-server:latest
```

## 4. Generate traffic

```sh
for i in $(seq 1 10); do
  curl -s -o /dev/null localhost:4221/
  curl -s -o /dev/null localhost:4221/echo/hi
  curl -s -o /dev/null localhost:4221/nope
done
```

## 5. Verify

```sh
# App stdout is clean JSON with the fields (not FORMATTER CRASH):
docker logs http-server | grep request.done | tail -1

# Metrics reached the Agent (over dd-net):
docker exec dd-agent agent status | grep -i "Metric Packets"
docker exec dd-agent agent dogstatsd-stats                        # per metric+tag breakdown

# Logs collected — ONLY the app container, shipped with no retries:
docker exec dd-agent agent status | grep -iA40 "Logs Agent" \
  | grep -iE "Service:|Source:|LogsSent|RetryCount"

# API key accepted (no 403s), forwarder healthy:
docker exec dd-agent agent status | grep -iA3 "API Keys status"
docker exec dd-agent agent health
```

In Datadog (app.ap2.datadoghq.com):
- **Metrics → Explorer** → `web.request.done.count`, `sum by` `status`/`method`
- **Logs → Search** → `service:codecrafters-http-server` (facets: `status`,
  `method`, `path`, `duration_ms`). Widen the time range if you don't see recent
  ones — logs only exist for moments the app actually served requests.

## Cost notes (free tier / trial)

- **Metrics** bill as *custom metrics* (100/host on Free). Keep tags
  low-cardinality — `method`/`status` only, never `path` (every `/echo/<x>`
  would be a new timeseries). The `distribution` expands into several custom
  metrics; drop it and keep only the `counter` to minimise the count.
- **Logs** are a separate meter (GB ingested + indexed events), not custom
  metrics — negligible at personal volume.


# Deploying to EC2

This runs the server as a Docker container on an Amazon Linux 2023 EC2
instance, listening on port `4221`.

Account / region used below (change to yours):

- AWS account: `662779349557`
- Region: `ap-southeast-1`
- ECR repo: `http-server`
- Port: `4221`

## 1. Give the instance permission to pull from ECR

The instance needs an **IAM role** (delivered via an *instance profile*) so the
AWS CLI can authenticate — EC2 reads temporary, auto-rotating credentials from
the instance metadata service (IMDS); nothing is stored on disk.

Attach a role with the `AmazonEC2ContainerRegistryReadOnly` policy:

- Console: **EC2 → select instance → Actions → Security → Modify IAM role**
- Or CLI (from a machine with your own creds, not the instance):

```sh
aws ec2 associate-iam-instance-profile \
  --instance-id i-xxxxxxxx \
  --iam-instance-profile Name=<your-instance-profile-name>
```

Verify on the instance — this must return a role ARN, not `NoCredentials`:

```sh
aws sts get-caller-identity
```

## 2. Build the image ON the instance

Build natively on the amd64 instance. Do **not** cross-build
`--platform linux/amd64` from an Apple Silicon Mac — the QEMU emulation crashes
the Erlang VM (`prim_tty:isatty` NIF error).

```sh
sudo dnf install -y git docker
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user   # log out/in after this for non-sudo docker

git clone https://github.com/Maxzimmerman/http-server-elixir.git
cd http-server-elixir

# --ulimit avoids Erlang's huge "port_tab" allocation (ll_alloc) that happens
# when the container's default open-file limit is enormous.
docker build --ulimit nofile=65536:65536 -t http-server:latest .
```

## 3. Run the container

```sh
docker rm -f my-elixir-app 2>/dev/null
docker run -d -p 4221:4221 --name my-elixir-app --restart always http-server:latest
docker ps          # should show status "Up" and 0.0.0.0:4221->4221/tcp
```

Test it locally on the instance:

```sh
curl -v http://localhost:4221
```

## 4. Reach it from outside

Add an inbound rule to the instance's **security group** allowing TCP `4221`
(from your IP, or `0.0.0.0/0` for testing). Then, from your machine:

```sh
curl -v http://<instance-public-ip>:4221
```

## (Optional) Pull from ECR instead of building on the instance

If you build elsewhere on a native amd64 host (CI, CodeBuild) and push to ECR:

```sh
REGISTRY="662779349557.dkr.ecr.ap-southeast-1.amazonaws.com"
aws ecr get-login-password --region ap-southeast-1 \
  | docker login --username AWS --password-stdin "$REGISTRY"
docker pull "$REGISTRY/http-server:latest"
docker run -d -p 4221:4221 --name my-elixir-app --restart always \
  "$REGISTRY/http-server:latest"
```

Note: `docker login` must use `--password-stdin` (piped from
`get-login-password`) — a plain `docker login` fails in non-interactive
contexts like user-data with "Cannot perform an interactive login from a non
TTY device".

## Debugging

```sh
# What the user-data / cloud-init script printed (and where it failed):
sudo cat /var/log/cloud-init-output.log

# Container logs (if it exits instead of staying Up):
docker logs my-elixir-app

# Confirm the instance has working credentials:
aws sts get-caller-identity

# Confirm an IAM role is attached (404 here = no role attached):
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

**Note:** user-data runs only **once, on first boot** — a reboot does not re-run
it. To re-run after fixing it: `sudo cloud-init clean --logs && sudo cloud-init init`.


