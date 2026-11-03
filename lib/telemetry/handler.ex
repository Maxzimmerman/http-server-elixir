defmodule Telemetry.Handler do
  @moduledoc """
  A local access-log handler for `[:web, :request, :done]`. This is the
  side-effect consumer (one log line per request); the Datadog metrics live in
  `Telemetry.Reporter`. Attach once at startup via `attach/0` — a handler is a
  one-time registration, never per request.
  """

  require Logger

  @handler_id "http-access-log"

  @spec attach() :: :ok
  def attach do
    :telemetry.attach(
      @handler_id,
      [:web, :request, :done],
      &__MODULE__.handle_event/4,
      nil
    )

    :ok
  end

  @doc false
  def handle_event([:web, :request, :done], %{duration: micros}, metadata, _config) do
    Logger.info("request.done",
      method: metadata.method,
      path: metadata.path,
      status: metadata.status,
      duration_ms: Float.round(micros / 1000, 1)
    )
  end
end
