defmodule Orchestrator do
  alias Protocol.{HTTPRequest, HTTPResponse}

  # Controller => Taget map
  @controllers %{
    "/" => Controllers.MainController,
    "/echo" => Controllers.EchoController,
    "/files" => Controllers.FileController,
    "/user-agent" => Controllers.UserAgentController
  }

  def deligate_request(%HTTPRequest{line: %{target: target}} = request) do
    with {:ok, controller} <- controller(target) do
      controller.handle_request(request)
    end
  end

  defp controller(target) do
    case Map.fetch(@controllers, endpoint(target)) do
      :error ->
        {:error, HTTPResponse.build(:not_found)}

      {:ok, controller} ->
        {:ok, controller}
    end
  end

  def endpoint(path) do
    case String.split(path, "/", trim: true) do
      [first | _rest] -> "/" <> first
      [] -> "/"
    end
  end
end
