defmodule AlchemicalReduction do
  def init(stream) do
    {Enum.to_list(stream), nil}
  end

  def process(polymer, nil) do
    leftover =
      polymer
      |> String.graphemes
      |> react
    {:halt, length(leftover)}
  end

  defp react(polymer, reacted \\ [ ])
  "abcdefghijklmnopqrstuvwxyz"
  |> String.graphemes
  |> Enum.map(fn lower ->
    upper = String.upcase(lower)
    [
      defp react([unquote(lower), unquote(upper) | rest], [prev | acc]) do
        react([prev | rest], acc)
      end,
      defp react([unquote(lower), unquote(upper) | rest], [ ]) do
        react(rest, [ ])
      end,
      defp react([unquote(upper), unquote(lower) | rest], [prev | acc]) do
        react([prev | rest], acc)
      end,
      defp react([unquote(upper), unquote(lower) | rest], [ ]) do
        react(rest, [ ])
      end
    ]
  end)
  defp react([first | rest], acc) do
    react(rest, [first | acc])
  end
  defp react([ ], acc), do: Enum.reverse(acc)
end

defmodule AlchemicalReductionPartTwo do
  defdelegate init(stream), to: AlchemicalReduction

  def process(polymer, nil) do
    best =
      polymer
      |> String.downcase
      |> String.graphemes
      |> Enum.uniq
      |> Enum.map(fn unit ->
        polymer
        |> String.replace(~r|#{unit}|i, "")
        |> AlchemicalReduction.process(nil)
        |> elem(1)
      end)
      |> Enum.min
    {:halt, best}
  end
end

Code.require_file "../advent_of_code.exs", __DIR__
AdventOfCode.process_file(
  AlchemicalReduction,
  AlchemicalReductionPartTwo,
  System.argv
)
