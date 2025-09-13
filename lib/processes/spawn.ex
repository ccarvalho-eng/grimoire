defmodule Grimoire.Processes.Spawn do
  @moduledoc """
  Demonstrates various ways to spawn processes in Elixir.
  """

  @doc """
  Spawns a simple process that returns :ok and terminates.

  Returns the PID of the spawned process.
  """
  def simple_spawn do
    spawn(fn -> :ok end)
  end

  @doc """
  Spawns a linked process that returns :ok and terminates.

  If the spawned process crashes, this process will also crash.
  Returns the PID of the spawned process.
  """
  def linked_spawn do
    spawn_link(fn -> :ok end)
  end

  @doc """
  Spawns a monitored process that returns :ok and terminates.

  Returns a tuple {PID, reference} where the reference can be used
  to receive DOWN messages when the process terminates.
  """
  def monitored_spawn do
    spawn_monitor(fn -> :ok end)
  end

  @doc """
  Spawns a process that sends a message back to the caller.

  The spawned process will send `{:response, "Task completed"}`
  back to the calling process before terminating.
  """
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
  def spawn_crash(reason \\ :normal) do
    spawn(fn -> exit(reason) end)
  end
end
