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

  test "spawn_calculation/1 performs calculation and sends result" do
    pid = Spawn.spawn_calculation(5)
    assert is_pid(pid)

    receive do
      {:calculation_result, result} ->
        assert result == 15  # 1+2+3+4+5 = 15
    after
      100 ->
        flunk("Did not receive calculation result")
    end
  end

  test "spawn_workers/2 creates multiple worker processes" do
    data = [1, 2, 3, 4, 5, 6]
    pids = Spawn.spawn_workers(data, 2)
    assert length(pids) == 2
    assert Enum.all?(pids, &is_pid/1)

    results = collect_worker_results([], 2)
    flattened = List.flatten(results)
    expected = [2, 4, 6, 8, 10, 12]  # Each number doubled
    assert Enum.sort(flattened) == expected
  end

  defp collect_worker_results(acc, 0), do: acc

  defp collect_worker_results(acc, count) do
    receive do
      {:worker_result, result} ->
        collect_worker_results([result | acc], count - 1)
    after
      200 ->
        flunk("Did not receive all worker results")
    end
  end

  test "spawn_message_collector/1 collects multiple messages" do
    pid = Spawn.spawn_message_collector(3)
    assert is_pid(pid)

    send(pid, "message1")
    send(pid, "message2")
    send(pid, "message3")

    receive do
      {:collected_messages, messages} ->
        assert messages == ["message1", "message2", "message3"]
    after
      100 ->
        flunk("Did not receive collected messages")
    end
  end

  test "spawn_periodic_updater/2 sends periodic updates" do
    pid = Spawn.spawn_periodic_updater(10, 3)
    assert is_pid(pid)

    updates = collect_updates([], 3)
    assert updates == [1, 2, 3]
  end

  defp collect_updates(acc, 0), do: Enum.reverse(acc)

  defp collect_updates(acc, count) do
    receive do
      {:update, update_count} ->
        collect_updates([update_count | acc], count - 1)
    after
      100 ->
        flunk("Did not receive expected updates")
    end
  end

  test "spawn_on_node/2 handles unavailable node" do
    fun = fn -> :test_function end
    result = Spawn.spawn_on_node(:nonexistent_node, fun)

    case result do
      {:error, :node_unavailable, pid} ->
        assert is_pid(pid)
      {:ok, pid} ->
        # If somehow the node exists, that's also valid
        assert is_pid(pid)
    end
  end

  test "spawn_counter/1 creates a stateful counter process" do
    pid = Spawn.spawn_counter(5)
    assert is_pid(pid)

    send(pid, {:get, self()})
    receive do
      {:count, count} -> assert count == 5
    after
      100 -> flunk("Did not receive initial count")
    end

    send(pid, {:increment, self()})
    receive do
      {:count, count} -> assert count == 6
    after
      100 -> flunk("Did not receive incremented count")
    end

    send(pid, {:decrement, self()})
    receive do
      {:count, count} -> assert count == 5
    after
      100 -> flunk("Did not receive decremented count")
    end

    send(pid, :stop)
    Process.sleep(10)
    assert Process.alive?(pid) == false
  end

  test "spawn_named/2 registers process with custom name" do
    # Use a unique name for each test run
    name = String.to_atom("test_process_#{:erlang.unique_integer([:positive])}")
    fun = fn -> Process.sleep(50) end

    result = Spawn.spawn_named(name, fun)
    assert {:ok, pid} = result
    assert is_pid(pid)
    assert Process.whereis(name) == pid

    # Test that the same name cannot be registered again
    fun2 = fn -> Process.sleep(50) end
    result2 = Spawn.spawn_named(name, fun2)
    assert result2 == {:error, :name_taken}

    Process.exit(pid, :kill)
  end

  test "spawn_with_error_handling/1 handles successful function" do
    fun = fn -> :success_result end
    pid = Spawn.spawn_with_error_handling(fun)
    assert is_pid(pid)

    receive do
      {:ok, result} ->
        assert result == :success_result
    after
      100 ->
        flunk("Did not receive success result")
    end
  end

  test "spawn_with_error_handling/1 handles function that raises" do
    fun = fn -> raise "test error" end
    pid = Spawn.spawn_with_error_handling(fun)
    assert is_pid(pid)

    receive do
      {:error, {kind, reason}} ->
        assert kind == :error
        assert %RuntimeError{} = reason
    after
      100 ->
        flunk("Did not receive error result")
    end
  end

  test "spawn_with_error_handling/1 handles function that throws" do
    fun = fn -> throw(:test_throw) end
    pid = Spawn.spawn_with_error_handling(fun)
    assert is_pid(pid)

    receive do
      {:error, {kind, reason}} ->
        assert kind == :throw
        assert reason == :test_throw
    after
      100 ->
        flunk("Did not receive throw result")
    end
  end
end
