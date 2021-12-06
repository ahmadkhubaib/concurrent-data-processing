defmodule PageConsumer do
  use GenStage
  require Logger

  def start_link(event) do
    Logger.info("PageConsumer received #{inspect(event)}")

    # we pretend we are doing a time consuming work
    Task.start_link(fn ->
      Scraper.work()
    end)
  end
end
