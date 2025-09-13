defmodule Grimoire.Processes.SpawnTest do
  use ExUnit.Case
  doctest Grimoire.Processes.Spawn

  alias Grimoire.Processes.Spawn

  test "simple_spawn/0 creates a process that terminates normally" do
    pid = Spawn.simple_spawn()
    assert is_pid(pid)

    Process.sleep(10)
    assert Process.alive?(pid) == false
  end

  test "linked_spawn/0 creates a linked process" do
    pid = Spawn.linked_spawn()
    assert is_pid(pid)

    Process.sleep(10)
    assert Process.alive?(pid) == false
  end

  test "monitored_spawn/0 returns PID and monitor reference" do
    {pid, ref} = Spawn.monitored_spawn()
    assert is_pid(pid)
    assert is_reference(ref)

    # Wait for DOWN message
    receive do
      {:DOWN, ^ref, :process, ^pid, reason} ->
        assert reason == :normal
    after
      100 ->
        flunk("Did not receive DOWN message")
    end
  end

  test "spawn_with_message/0 sends message back to caller" do
    pid = Spawn.spawn_with_message()
    assert is_pid(pid)

    # Wait for the message
    receive do
      {:response, message} ->
        assert message == "Task completed"
    after
      100 ->
        flunk("Did not receive response message")
    end
  end

  test "spawn_crash/1 creates a process that exits with given reason" do
    pid = Spawn.spawn_crash(:custom_error)
    {_pid, ref} = spawn_monitor(fn -> Process.monitor(pid) end)

    receive do
      {:DOWN, ^ref, :process, _monitored_pid, :normal} ->
        # The monitor process finished normally
        :ok
    after
      100 ->
        flunk("Monitor process did not complete")
    end

    Process.sleep(10)
    assert Process.alive?(pid) == false
  end

  test "spawn_crash/0 uses :normal as default reason" do
    pid = Spawn.spawn_crash()
    assert is_pid(pid)

    Process.sleep(10)
    assert Process.alive?(pid) == false
  end
end
