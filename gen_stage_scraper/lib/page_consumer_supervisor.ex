defmodule PageConsumerSupervisor do
  use ConsumerSupervisor
  require Logger

  def start_link(_args) do
    ConsumerSupervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    Logger.info("Page ConsumerSupervisor init")

    children = [%{
      id: PageConsumer,
      restart: :transient,
      start: {PageConsumer, :start_link, []}
    }]

    opts = [strategy: :one_for_one, subscribe_to: [{PageProducer, max_demand: 2}]]

    ConsumerSupervisor.init(children, opts)
  end
end
