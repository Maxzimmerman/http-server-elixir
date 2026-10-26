defmodule Orchestrator do
  alias Controllers
  # Controller => Taget map
  @controllers %{
    MainController => "/",
    EchoController => "/echo",
    Controllers.FileController => "/files"
  }

  def deligate_request(%HTTPRequest{line: %{target: target}} = request) do
    with {:ok, controller} <- controller(target) do
      controller.handle_request(request)
    end
  end

  defp controller(target) do
    case Map.fetch(@controllers, endpoint(target)) do
      [] ->
        {:error,
         """
         HTTP/1.1 404 Not Found\r\n\r\n
         """}

      controller ->
        IO.inspect(@controllers)
        IO.inspect(controller)
        IO.puts(target)
        IO.inspect(Map.fetch(@controllers, target))
        IO.inspect(endpoint(target))
        {:ok, controller}
    end
  end

  def endpoint(path) do
    case String.split(path, "/", trim: true) do
      [first | _rest] -> first <> "/"
      [] -> "/"
    end
  end
end
