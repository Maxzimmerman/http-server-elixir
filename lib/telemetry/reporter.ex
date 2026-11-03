defmodule Telemetry.Reporter do
  @moduledoc """
  Supervises the Datadog metrics pipeline. `TelemetryMetricsStatsd` attaches a
  handler for every metric in `metrics/0` and ships them, in DogStatsD wire
  format, as UDP to the Datadog Agent (`DD_AGENT_HOST:DD_DOGSTATSD_PORT`). The
  Agent is what forwards them on to Datadog — the app never talks to Datadog's
  API directly.

  Add a metric to `metrics/0` and it is forwarded automatically; no handler
  wiring by hand.
  """

  use Supervisor

  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {TelemetryMetricsStatsd,
       metrics: metrics(),
       formatter: :datadog,
       host: System.get_env("DD_AGENT_HOST", "localhost"),
       port: String.to_integer(System.get_env("DD_DOGSTATSD_PORT", "8125"))}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  The metric catalog. The metric name splits into an event name (all but the
  last segment) and a measurement key (the last). So both metrics below read
  the `[:web, :request, :done]` event: `counter` tallies occurrences, and
  `distribution` aggregates the `:duration` measurement. Tags come from the
  event metadata — kept to `method`/`status` to bound cardinality.
  """
  def metrics do
    [
      counter("web.request.done.count",
        tags: [:method, :status]
      ),
      distribution("web.request.done.duration",
        unit: {:microsecond, :millisecond},
        tags: [:method, :status]
      )
    ]
  end
end
