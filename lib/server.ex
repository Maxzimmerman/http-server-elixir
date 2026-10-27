defmodule Server do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> Adapters.HTTPServer.listen() end}],
      strategy: :one_for_one
    )
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
