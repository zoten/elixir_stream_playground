defmodule M do
  def run_enum, do: do_run_enum(&check_mem/1)
  def run_stream, do: do_run_stream(&check_mem/1)
  def run_genserver, do: do_run_genserver()

  defp do_run_enum(checker) do
    IO.puts("1 - Enums")
    1..1000000
    |> checker.()
    |> Enum.chunk_every(500)
    |> checker.()
    |> Enum.flat_map(&multi_enum/1)
    |> checker.()

    :ok
  end

  defp do_run_stream(checker) do
    IO.puts("2 - Streams")
    1..1000000
    |> checker.()
    |> Stream.chunk_every(500)
    |> checker.()
    |> Stream.flat_map(&multi_stream/1)
    |> checker.()
    |> Enum.to_list()
    |> checker.()

    :ok
  end

  defp do_run_genserver do
    task_enum = Task.async(fn ->
      pid = self()

      do_run_enum(&check_process_mem(&1, pid))
    end)
    Task.await(task_enum)

    task_stream = Task.async(fn ->
      pid = self()

      do_run_stream(&check_process_mem(&1, pid))
    end)
    Task.await(task_stream)
    :ok
  end

  defp check_process_mem(input, self_pid) do
    IO.inspect(:erlang.process_info(self_pid, :memory), label: "erl process mem")
    input
  end

  defp check_mem(input) do
    IO.inspect(:erlang.memory(:total), label: "erl mem")
    input
  end

  defp multi_enum(chunk) do
    Enum.map(chunk, fn item ->
      [item, item + 1, item + 2, item + 3]
    end)
  end

  defp multi_stream(chunk) do
    Stream.map(chunk, fn item ->
      [item, item + 1, item + 2, item + 3]
    end)
  end
end

case System.argv() |> Enum.at(0)  do
  "stream" -> M.run_stream()
  "enum" -> M.run_enum()
  "genserver" -> M.run_genserver()
  _ -> IO.puts("Use as `elixir streammem.exs [stream|enum|genserver]`")
end
