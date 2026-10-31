defmodule Controllers.HealthController do
  alias Protocol.{HTTPRequest, HTTPResponse}

  def index(%HTTPRequest{line: %{target: "/health"}, close: close}) do
    IO.inspect(S3Storage.fetch())
    {:ok, HTTPResponse.build(:ok, close: close)}
  end
end
