defmodule SendServer do
  use GenServer

  require IEx

  @doc """
    These are the accepted return values from init
    1. {:ok, state}
    2. {:ok, state, {:continue, term}} -> as it is synchronous call so we should not do something which can block init, like databse records fething
    3. :ignore -> stop the init, without restarting the process from supervisor
    4. {:stop, reason} -> stop the init with message to supervisor to restart
    3 & 4 are used to handle invalid arguments or othercase when something is wrong and we dont want genserver to init
  """
  def init(args) do
    IO.puts("in init, Received arguments #{inspect(args)}")
    max_retries = Keyword.get(args, :max_retries, 5)
    state = %{emails: [], max_retries: max_retries}
    Process.send_after(self(), :retry, 5000)
    {:ok, state, {:continue, :load_database}}
  end

  @doc """
    These are the accepted return values from handle_continue
    {:noreply, new_state}
    {:noreply, new_state, {:continue, term}} -> to handle something else after this
    {:stop, reason, new_state}
  """
  def handle_continue(:load_database, state) do
    IO.puts("In handle_continue, previous state is => #{inspect(state)}")
    IO.puts("Loading database....")
    Process.sleep(3000)
    # load something from database and update the state

    new_state = %{state | emails: [%{email: "handle_continue@noreply.com",status: "failed", retries: 0}] ++ state.emails}
    IO.puts("In handle_continue, new state is => #{inspect(new_state)}")
    {:noreply, state: new_state}
  end

  @doc """
    These are the accepted return values from handle_call
    {:reply, reply, new_state}
    {:reply, reply, new_state, {:continue, term}} -> to handle something else after this
    {:stop, reason, reply, new_state}
  """
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @doc """
    These are the accepted return values from handle_cast
    {:noreply, new_state}
    {:noreply, new_state, {:continue, term}}
    {:stop, reason, new_state}
  """
  def handle_cast({:send, email}, state) do
    status = case Sender.send_email(email) do
      {:ok, _} -> "sent"
      :error -> "failed"
    end

    state = get_state_head(state)
    new_state = %{state | emails: [%{email: email, status: status, retries: 0}] ++ state.emails}
    {:noreply, new_state}
  end

  def handle_info(:retry, [{:state, current_state}|_tail]) do
    {failed, done} =
      Enum.split_with(current_state.emails, fn email ->
        email.status == "failed" && email.retries < current_state.max_retries
      end)

    retried =
      Enum.map(failed, fn item ->
        IO.puts("Retrying #{item.email}")
        new_status =
          case Sender.send_email(item.email) do
          {:ok, _} -> "sent"
          :error -> "failed"
        end
        %{email: item.email, status: new_status, retries: item.retries + 1}
      end)
    Process.send_after(self(), :retry, 5000)
    new_state = %{current_state | emails: retried ++ done}
    {:noreply, [{:state, new_state}]} #send the same structure as we pattern matched on line 66, otherwise it will be error
  end

  def terminate(reason, _state) do
    IO.puts("Terminating with #{reason}")
  end

  defp get_state_head([{:state, current_state}|_tail] = state) when is_list(state), do: current_state

  defp get_state_head(current_state), do: current_state
end
