defmodule JobProcessor do
  alias JobProcessor.{JobSupervisor, JobRunner}

  def running_imports() do
    match_all = {:"$1", :"$2", :"$3"}
    guards = [{:"==", :"$3", "import"}]
    map_result = [%{id: :"$1", pid: :"$2", type: :"$3"}]
    Registry.select(JobProcessor.JobRegistry,[{match_all, guards, map_result}])
  end

  def start_job(args) do
    if length(running_imports()) >=5 do
      {:error, :import_quota_reached}
    else
      DynamicSupervisor.start_child(JobRunner, {JobSupervisor, args})
    end
  end
end
