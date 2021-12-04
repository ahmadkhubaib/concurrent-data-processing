defmodule JobProcessor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    job_runner_config = [
      strategy: :one_for_one,
      name: JobProcessor.JobRunner,
      max_seconds: 30_000
    ]
    children = [
      {Registry, keys: :unique, name: JobProcessor.JobRegistry},
      {DynamicSupervisor, job_runner_config}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JobProcessor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
