defmodule Orchestrator do
  # Controller => Taget map
  @controllers %{Controllers.MainController => "/"}

  def deligate_request(%HTTPRequest{line: %{target: target}} = request) do
    with {:ok, controller} <- controller(target) do
      controller.handle_request(request)
    end
  end

  defp controller(target) do
    case Map.get(@controllers, target) do
      [] ->
        {:error,
         """
         HTTP/1.1 404 Not Found\r\n\r\n
         """}

      controller ->
        {:ok, controller}
    end
  end
end
