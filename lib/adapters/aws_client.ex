defmodule Adapters.AWSClient do
  @moduledoc """
  Outbound adapter: talks to AWS on behalf of the system.

  Keep this layer thin. It owns only the mechanics of the call — building the
  request, signing/auth, firing it and marshalling the raw result back into
  plain Elixir terms. The decision of *when* and *why* to call AWS lives in a
  controller or domain module, not here, so the boundary stays a dumb edge and
  the callers stay testable.
  """

  # Drop outbound AWS calls here, e.g.:
  #
  #   @spec put_object(bucket :: String.t(), key :: String.t(), body :: binary()) ::
  #           {:ok, term()} | {:error, term()}
  #   def put_object(bucket, key, body) do
  #     ...
  #   end
end
