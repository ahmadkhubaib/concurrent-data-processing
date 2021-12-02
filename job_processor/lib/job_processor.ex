defmodule JobProcessor do
  alias JobProcessor.{JobSupervisor, JobRunner}

  def start_job(args) do
    DynamicSupervisor.start_child(JobRunner, {JobSupervisor, args})
  end
end
