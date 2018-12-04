defmodule ReposeRecord do
  defmodule Record do
    defstruct ~w[date time guard sleeping? waking?]a
  end

  defstruct guard: nil, slept_at: nil, overall: Map.new, timed: Map.new

  def init(stream) do
    {Enum.sort(stream), %__MODULE__{ }}
  end

  def process(record, state) do
    parsed = parse(record)
    record_event(state, parsed)
  end

  def answer(state) do
    laziest_guard =
      state.overall
      |> Enum.max_by(fn {_guard, total} -> total end)
      |> elem(0)
    sleepiest_time =
      state.timed
      |> Map.fetch!(laziest_guard)
      |> Enum.max_by(fn {_minute, total} -> total end)
      |> elem(0)
    laziest_guard * sleepiest_time
  end

  defp parse(record) do
    captures =
      Regex.named_captures(
        ~r|
          \A \[
          (?<date>\d{4}-\d{2}-\d{2})
          \s+
          (?<time>\d{2}:\d{2})
          \] \s+
          (?<event>.+)
          \z
        |x,
        record
      )
    event = Map.fetch!(captures, "event")
    %Record{
      date: Map.fetch!(captures, "date"),
      time: Map.fetch!(captures, "time"),
      guard: Regex.named_captures(~r{#(?<guard>\d+)}, event)["guard"],
      sleeping?: event == "falls asleep",
      waking?: event == "wakes up"
    }
  end

  defp record_event(state, %Record{guard: guard}) when not is_nil(guard) do
    %__MODULE__{state | guard: String.to_integer(guard)}
  end
  defp record_event(state, %Record{sleeping?: true} = parsed) do
    %__MODULE__{state | slept_at: minutes(parsed.time)}
  end
  defp record_event(state, %Record{waking?: true} = parsed) do
    woke_at = minutes(parsed.time)
    period = woke_at - state.slept_at
    %__MODULE__{
      state |
      overall: Map.update(state.overall, state.guard, period, &(&1 +period)),
      timed: Enum.reduce(
        state.slept_at..(woke_at - 1),
        state.timed,
        fn minute, new_timed ->
          Map.update(
            new_timed,
            state.guard,
            %{minute => 1},
            fn by_minute -> Map.update(by_minute, minute, 1, &(&1 + 1)) end
          )
        end
      )
    }
  end

  defp minutes(time), do: time |> String.slice(3..4) |> String.to_integer
end

defmodule ReposeRecordPartTwo do
  defdelegate init(stream), to: ReposeRecord
  defdelegate process(record, state), to: ReposeRecord

  def answer(state) do
    {laziest_guard, {sleepiest_time, _total}} =
      state.timed
      |> Enum.map(fn {guard, by_minute} ->
        {guard, Enum.max_by(by_minute, fn {_minute, total} -> total end)}
      end)
      |> Enum.max_by(fn {_guard, {_minute, total}} -> total end)
    laziest_guard * sleepiest_time
  end
end

Code.require_file "../advent_of_code.exs", __DIR__
AdventOfCode.process_file(
  ReposeRecord,
  ReposeRecordPartTwo,
  System.argv
)
