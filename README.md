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


