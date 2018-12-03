defmodule NoMatterHowYouSliceIt do
  def init(stream) do
    {stream, Map.new}
  end

  def process(claim, inches) do
    claim
    |> squares_for
    |> record_all(inches)
  end

  def answer(inches) do
    inches
    |> Enum.filter(fn {_xy, count} -> count >= 2 end)
    |> Enum.count
  end

  def squares_for(claim) do
    [left, top, width, height] =
      ~r{\A#\S+\s+@\s+(\d+),(\d+):\s+(\d+)x(\d+)\z}
      |> Regex.run(claim, capture: :all_but_first)
      |> Enum.map(&String.to_integer/1)
    for x <- left..(left + width - 1), y <- top..(top + height - 1), do: {x, y}
  end

  defp record_all(squares, inches) do
    Enum.reduce(squares, inches, fn square, new_inches ->
      Map.update(new_inches, square, 1, &(&1 + 1))
    end)
  end
end

defmodule NoMatterHowYouSliceItPartTwo do
  defstruct claims: [ ], inches: Map.new

  def init(stream) do
    {stream, %__MODULE__{ }}
  end

  def process(claim, state) do
    %__MODULE__{
      claims: [claim | state.claims],
      inches: NoMatterHowYouSliceIt.process(claim, state.inches)
    }
  end

  def answer(state) do
    state.claims
    |> Enum.find(fn claim ->
      claim
      |> NoMatterHowYouSliceIt.squares_for
      |> Enum.all?(fn xy -> Map.fetch!(state.inches, xy) == 1 end)
    end)
    |> String.replace(~r{\A#(\d+).+\z}, "\\1")
  end
end

Code.require_file "../advent_of_code.exs", __DIR__
AdventOfCode.process_file(
  NoMatterHowYouSliceIt,
  NoMatterHowYouSliceItPartTwo,
  System.argv
)
