defmodule Readmark.Workers.ObanLogger do
  require Logger

  @events [[:oban, :job, :start], [:oban, :job, :stop], [:oban, :job, :exception]]

  def attach do
    :telemetry.attach_many("oban-logger", @events, &__MODULE__.handle_event/4, [])
  end

  def handle_event([:oban, :job, :exception], _measure, meta, _) do
    Logger.error(Exception.format(:error, meta.error, meta.stacktrace))
  end

  def handle_event([:oban, :job, :start], measure, meta, _) do
    Logger.notice("[Oban] :started #{meta.worker} at #{measure.system_time}")
  end

  def handle_event([:oban, :job, event], measure, meta, _) do
    Logger.notice("[Oban] #{event} #{meta.worker} ran in #{measure.duration}")
  end
end
