defmodule ChronalCalibration do
  def init(stream) do
    {stream, 0}
  end

  def process(change, current) do
    {:cont, current + String.to_integer(String.trim(change))}
  end
end

defmodule ChronalCalibrationPartTwo do
  defstruct current: 0, seen: MapSet.new([0])

  def init(stream) do
    {Stream.cycle(stream), %__MODULE__{ }}
  end

  def process(change, state) do
    new_frequency = state.current + String.to_integer(String.trim(change))
    if MapSet.member?(state.seen, new_frequency) do
      {:halt, new_frequency}
    else
      {
        :cont,
        %__MODULE__{
          current: new_frequency,
          seen: MapSet.put(state.seen, new_frequency)
        }
      }
    end
  end
end

Code.require_file "../advent_of_code.exs", __DIR__
AdventOfCode.process_file(
  ChronalCalibration,
  ChronalCalibrationPartTwo,
  System.argv
)
