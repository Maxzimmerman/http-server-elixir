defmodule Controllers.MainController do
  alias Protocol.{HTTPRequest, HTTPResponse}

  def index(%HTTPRequest{close: close}) do
    {:ok, HTTPResponse.build(:ok, close: close)}
  end
end
