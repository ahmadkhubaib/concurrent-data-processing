defmodule JobProcessor.Job do
  use GenServer, restart: :transient
  require Logger

  alias JobProcessor.Job

  defstruct [:work, :id, :max_retries, retries: 0, status: "new"]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    work = Keyword.fetch!(args, :work)
    id = Keyword.get(args, :id, random_job_id())
    max_retries = Keyword.get(args, :max_retries, 3)

    state = %Job{work: work, id: id, max_retries: max_retries}
    {:ok, state, {:continue, :run}}
  end

  def handle_continue(:run, state) do
    new_state = state.work.() |> handle_job_result(state)

    if new_state.status == "errored" do
      Process.send_after(self(), :retry, 5000)
      {:noreply, new_state}
    else
      Logger.info("Job exiting #{state.id}")
      {:stop, :normal, new_state}
    end
  end

  def handle_info(:retry, state) do
    {:noreply, state, {:continue, :run}}
  end

  defp random_job_id(), do: :crypto.strong_rand_bytes(5) |> Base.url_encode64(padding: false)

  defp handle_job_result({:ok, _}, state) do
    Logger.info("Job completed #{state.id}")
    %Job{state | status: "done"}
  end

  defp handle_job_result(:error, %{status: "new"} = state) do
    Logger.warn("Job errored #{state.id}")
    %Job{state | status: "errored"}
  end

  defp handle_job_result(:error, %{status: "errored"} = state) do
    Logger.warn("Job retry failed #{state.id}")
    new_state = %Job{state | retries: state.retries + 1}

    if new_state.retries == state.max_retries do
      %Job{state | status: "failed"}
    else
      new_state
    end
  end

  defp handle_job_result(msg, state) do
    IO.inspect(msg, label: "++++++++++++++++++++++++++++++++")
    IO.inspect(state, label: "--------------------------------")
    %Job{state | status: "failed"}
  end
end
