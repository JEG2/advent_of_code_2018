defmodule MemoryManeuver do
  defmodule Node do
    defstruct ~w[child_count metadata_count children metadata]a

    def parse(numbers) do
      numbers
      |> parse_header
      |> parse_children
      |> parse_metadata
    end

    defp parse_header(numbers) do
      [child_count, metadata_count] = Enum.take(numbers, 2)
      {
        %__MODULE__{child_count: child_count, metadata_count: metadata_count},
        Enum.drop(numbers, 2)
      }
    end

    defp parse_children({node, numbers}) do
      parsed =
        Stream.iterate({nil, numbers}, fn {_child, remaining} ->
          Node.parse(remaining)
        end)
        |> Enum.take(node.child_count + 1)
        |> Enum.drop(1)
      {
        %__MODULE__{node | children: Enum.map(parsed, &elem(&1, 0))},
        elem(List.last(parsed) || {nil, numbers}, 1)
      }
    end

    defp parse_metadata({node, numbers}) do
      metadata = Enum.take(numbers, node.metadata_count)
      {
        %__MODULE__{node | metadata: metadata},
        Enum.drop(numbers, node.metadata_count)
      }
    end
  end

  def init(stream) do
    {Enum.to_list(stream), nil}
  end

  def process(license, nil) do
    {root, [ ]} =
      license
      |> String.split(~r{\s+}, trim: true)
      |> Enum.map(&String.to_integer/1)
      |> Node.parse
    root
  end

  def answer(root) do
    sum_metadata([root])
  end

  defp sum_metadata(nodes) do
    Enum.reduce(nodes, 0, fn node, sum ->
      sum + Enum.sum(node.metadata) + sum_metadata(node.children)
    end)
  end
end

defmodule MemoryManeuverPartTwo do
  alias MemoryManeuver.Node

  defdelegate init(stream), to: MemoryManeuver
  defdelegate process(license, ignored), to: MemoryManeuver

  def answer(root) do
    sum_metadata([root])
  end

  defp sum_metadata(nodes) do
    Enum.reduce(nodes, 0, fn node, sum -> sum + value(node) end)
  end

  defp value(nil), do: 0
  defp value(%Node{children: [ ]} = node), do: Enum.sum(node.metadata)
  defp value(node) do
    node.metadata
    |> Enum.map(fn i -> node.children |> Enum.at(i - 1) |> value end)
    |> Enum.sum
  end
end

Code.require_file "../advent_of_code.exs", __DIR__
AdventOfCode.process_file(
  MemoryManeuver,
  MemoryManeuverPartTwo,
  System.argv
)
