defmodule Telemetry.Handler do
  require Logger

  def handle_event([:web, :request, :done], measurements, metadata, _config) do
    Logger.info(
      "[#{metadata.request_path}] #{metadata.status_code} sent in #{measurements.latency}"
    )
  end
end
