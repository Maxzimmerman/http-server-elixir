defmodule Orchestrator do
  alias Protocol.{HTTPRequest, HTTPResponse}

  # The single source of routing: `{method, endpoint} => {controller, action}`.
  # Both the method and the path segment are matched here, so a controller never
  # re-decides which request it handles — it only builds a response for the
  # action it was handed. Any method/path not in this table is a 404.
  @routes %{
    {"GET", "/"} => {Controllers.MainController, :index},
    {"GET", "/echo"} => {Controllers.EchoController, :echo},
    {"GET", "/user-agent"} => {Controllers.UserAgentController, :show},
    {"GET", "/files"} => {Controllers.FilesController, :read},
    {"POST", "/files"} => {Controllers.FilesController, :write},
    {"GET", "/health"} => {Controllers.HealthController, :index},
    {"GET", "/s3_files"} => {Controllers.AWSFilesController, :read},
    {"POST", "/s3_files"} => {Controllers.AWSFilesController, :write}
  }

  def delegate_request(%HTTPRequest{line: %{method: method, target: target}} = request) do
    with {:ok, {controller, action}} <- route(method, target) do
      apply(controller, action, [request])
    end
  end

  defp route(method, target) do
    case Map.fetch(@routes, {method, endpoint(target)}) do
      {:ok, action} -> {:ok, action}
      :error -> {:error, HTTPResponse.build(:not_found)}
    end
  end

  defp endpoint(path) do
    case String.split(path, "/", trim: true) do
      [first | _rest] -> "/" <> first
      [] -> "/"
    end
  end
end
