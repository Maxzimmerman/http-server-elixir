defmodule Controllers.EchoController do
  alias Protocol.{HTTPRequest, HTTPResponse}

  def echo(%HTTPRequest{line: %{target: "/echo/" <> str}, close: close} = request) do
    {:ok,
     HTTPResponse.build(:ok,
       content_type: :text,
       body: str,
       encodings: HTTPRequest.accept_encodings(request),
       close: close
     )}
  end

  # `/echo` with no value segment isn't a route this controller can serve.
  def echo(%HTTPRequest{}), do: {:error, HTTPResponse.build(:not_found)}
end
