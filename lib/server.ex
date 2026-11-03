defmodule Server do
  use Application

  def start(_type, _args) do
    # Attach event handlers before anything can serve a request, so no request
    # fires the event un-hooked. The metrics reporter attaches its own handlers
    # when it starts as a supervised child below.
    Telemetry.Handler.attach()

    opts = [strategy: :one_for_one]

    children = [
      Telemetry.Reporter,
      {Task, fn -> Adapters.HTTPServer.listen() end}
    ]

    Supervisor.start_link(children, opts)
  end

  def main(_args) do
    {:ok, _pid} = Application.ensure_all_started(:codecrafters_http_server)
    configure_directory(System.argv())
    Process.sleep(:infinity)
  end

  defp configure_directory(["--directory", dir]) do
    Application.put_env(:codecrafters_http_server, :directory, dir)
  end

  defp configure_directory(_argv), do: :ok
end
