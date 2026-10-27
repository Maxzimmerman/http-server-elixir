defmodule Controllers.UserAgentController do
  alias Protocol.{HTTPRequest, HTTPResponse}

  def show(%HTTPRequest{close: close} = request) do
    {:ok, HTTPResponse.build(:ok, content_type: :text, body: HTTPRequest.user_agent(request), close: close)}
  end
end
