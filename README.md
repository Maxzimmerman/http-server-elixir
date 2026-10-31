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
curl -v http://localhost:4221/echo/hello

# User-Agent endpoint — responds with the User-Agent header value
curl -v -H "User-Agent: foobar/1.2.3" http://localhost:4221/user-agent

# Files endpoint (GET) — reads a file from --directory
echo -n "file contents here" > /tmp/foo.txt
curl -v http://localhost:4221/files/foo.txt

# Files endpoint (POST) — writes a file into --directory
curl -v --data "12345" -H "Content-Type: application/octet-stream" \
  http://localhost:4221/files/newfile.txt

# Connection: close — the server echoes a `Connection: close` response header
# and closes the connection after responding
curl -v -H "Connection: close" http://localhost:4221/echo/hello

curl -v --data "12345" \
  -H "Connection: close" \
  -H "Content-Type: application/octet-stream" \
  http://localhost:4000/s3_files/a.txt

curl -v http://localhost:4221/s3_files/foo.txt
```

Use `curl -v` to inspect the status line and headers (`Content-Type`,
`Content-Length`, etc.), which is what most stages are tested on.


