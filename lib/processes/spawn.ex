defmodule Grimoire.Processes.Spawn do
  @moduledoc """
  Demonstrates various ways to spawn processes in Elixir.
  """

  @doc """
  Spawns a simple process that returns :ok and terminates.

  Returns the PID of the spawned process.
  """
  @spec simple_spawn() :: pid()
  def simple_spawn do
    spawn(fn -> :ok end)
  end

  @doc """
  Spawns a linked process that returns :ok and terminates.

  If the spawned process crashes, this process will also crash.
  Returns the PID of the spawned process.
  """
  @spec linked_spawn() :: pid()
  def linked_spawn do
    spawn_link(fn -> :ok end)
  end

  @doc """
  Spawns a monitored process that returns :ok and terminates.

  Returns a tuple {PID, reference} where the reference can be used
  to receive DOWN messages when the process terminates.
  """
  @spec monitored_spawn() :: {pid(), reference()}
  def monitored_spawn do
    spawn_monitor(fn -> :ok end)
  end

  @doc """
  Spawns a process that sends a message back to the caller.

  The spawned process will send `{:response, "Task completed"}`
  back to the calling process before terminating.
  """
  @spec spawn_with_message() :: pid()
  def spawn_with_message do
    caller = self()

    spawn(fn ->
      send(caller, {:response, "Task completed"})
      :ok
    end)
  end

  @doc """
  Spawns a process that crashes with a given reason.

  Useful for testing error handling and process supervision.
  """
  @spec spawn_crash(term()) :: pid()
  def spawn_crash(reason \\ :normal) do
    spawn(fn -> exit(reason) end)
  end

  @doc """
  Spawns a process that performs a calculation and sends the result back.

  The spawned process will calculate the sum of numbers from 1 to n
  and send the result back to the caller.
  """
  @spec spawn_calculation(non_neg_integer()) :: pid()
  def spawn_calculation(n) do
    caller = self()

    spawn(fn ->
      result = Enum.sum(1..n)
      send(caller, {:calculation_result, result})
    end)
  end

  @doc """
  Spawns multiple worker processes that each handle a portion of work.

  Creates `count` worker processes, each receiving a chunk of the data
  and sending results back to the caller.
  """
  @spec spawn_workers(list(), pos_integer()) :: [pid()]
  def spawn_workers(data, count) when is_list(data) and count > 0 do
    caller = self()
    chunk_size = max(1, div(length(data), count))
    chunks = Enum.chunk_every(data, chunk_size)

    Enum.map(chunks, fn chunk ->
      spawn(fn ->
        # Simulate work by doubling each number
        result = Enum.map(chunk, &(&1 * 2))
        send(caller, {:worker_result, result})
      end)
    end)
  end

  @doc """
  Spawns a process that waits for multiple messages before responding.

  The spawned process will collect `count` messages and then send
  all collected messages back to the caller.
  """
  @spec spawn_message_collector(non_neg_integer()) :: pid()
  def spawn_message_collector(count) do
    caller = self()

    spawn(fn ->
      messages = collect_messages([], count)
      send(caller, {:collected_messages, messages})
    end)
  end

  defp collect_messages(acc, 0), do: Enum.reverse(acc)

  defp collect_messages(acc, count) do
    receive do
      message ->
        collect_messages([message | acc], count - 1)
    end
  end

  @doc """
  Spawns a long-running process that periodically sends updates.

  The process will send a status update every `interval` milliseconds
  for a total of `updates` times before terminating.
  """
  @spec spawn_periodic_updater(non_neg_integer(), non_neg_integer()) :: pid()
  def spawn_periodic_updater(interval, updates) do
    caller = self()

    spawn(fn ->
      send_periodic_updates(caller, interval, updates, 1)
    end)
  end

  defp send_periodic_updates(_caller, _interval, 0, _count), do: :ok

  defp send_periodic_updates(caller, interval, remaining, count) do
    send(caller, {:update, count})
    Process.sleep(interval)
    send_periodic_updates(caller, interval, remaining - 1, count + 1)
  end

  @doc """
  Spawns a process on a specific node (for distributed systems).

  If the node is available, spawns the process there. Otherwise,
  spawns locally and returns an error tuple.
  """
  @spec spawn_on_node(node(), function()) :: {:ok, pid()} | {:error, :node_unavailable, pid()}
  def spawn_on_node(node, fun) when is_atom(node) and is_function(fun) do
    if Node.ping(node) == :pong do
      pid = Node.spawn(node, fun)
      {:ok, pid}
    else
      pid = spawn(fun)
      {:error, :node_unavailable, pid}
    end
  end

  @doc """
  Spawns a process that acts as a simple counter server.

  The process maintains a counter state and responds to :increment,
  :decrement, and :get messages.
  """
  @spec spawn_counter(integer()) :: pid()
  def spawn_counter(initial_value \\ 0) do
    spawn(fn -> counter_loop(initial_value) end)
  end

  defp counter_loop(count) do
    receive do
      {:increment, caller} ->
        new_count = count + 1
        send(caller, {:count, new_count})
        counter_loop(new_count)

      {:decrement, caller} ->
        new_count = count - 1
        send(caller, {:count, new_count})
        counter_loop(new_count)

      {:get, caller} ->
        send(caller, {:count, count})
        counter_loop(count)

      :stop ->
        :ok
    end
  end

  @doc """
  Spawns a process with a custom name registration.

  The process is registered with the given name and can be messaged
  using the name instead of the PID.
  """
  @spec spawn_named(atom(), function()) :: {:ok, pid()} | {:error, :name_taken}
  def spawn_named(name, fun) when is_atom(name) and is_function(fun) do
    case Process.whereis(name) do
      nil ->
        pid = spawn(fun)
        try do
          Process.register(pid, name)
          {:ok, pid}
        rescue
          ArgumentError ->
            Process.exit(pid, :kill)
            {:error, :name_taken}
        end

      _existing_pid ->
        {:error, :name_taken}
    end
  end

  @doc """
  Spawns a process that handles errors gracefully with try/catch.

  The process will attempt to execute the given function and send
  back either the result or the error that occurred.
  """
  @spec spawn_with_error_handling(function()) :: pid()
  def spawn_with_error_handling(fun) when is_function(fun) do
    caller = self()

    spawn(fn ->
      result =
        try do
          {:ok, fun.()}
        catch
          kind, reason ->
            {:error, {kind, reason}}
        end

      send(caller, result)
    end)
  end
end
