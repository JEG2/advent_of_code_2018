defmodule ReservoirResearch do
  defstruct meters: Map.new, depth: nil, flow: [fall: {500, 0}]

  def parse(lines) do
    state = %__MODULE__{ }
    new_meters = Enum.reduce(lines, state.meters, fn line, meters ->
      line
      |> parse_meters
      |> Enum.reduce(meters, fn xy, meters ->
        Map.put(meters, xy, :clay)
      end)
    end)
    {min_y, max_y} =
      new_meters |> Map.keys |> Enum.map(&elem(&1, 1)) |> Enum.min_max
    %__MODULE__{
      state |
      meters: new_meters,
      depth: max_y,
      flow: [fall: {500, min_y - 1}]
    }
  end

  def dump_to_file(meters, state) do
    File.open!("dump.txt", ~w[write]a, fn f ->
      {min_x, max_x} =
        meters |> Map.keys |> Enum.map(&elem(&1, 0)) |> Enum.min_max
      IO.puts(
        f,
        String.duplicate(".", 500 - min_x) <>
          "+" <>
          String.duplicate(".", max_x - 500)
      )
      Enum.each(1..state.depth, fn y ->
        IO.puts f, Enum.map(min_x..max_x, fn x ->
          case Map.get(meters, {x, y}, :sand) do
            :clay -> "#"
            :wet -> "|"
            :water -> "~"
            :sand -> "."
          end
        end)
      end)
    end)
    meters
  end

  def fill(%__MODULE__{flow: [ ]} = state), do: state
  def fill(%__MODULE__{flow: [{:fall, {x, y}} | flow]} = state) do
    (y + 1)..state.depth
    |> Enum.find(fn lower_y ->
      Map.get(state.meters, {x, lower_y}) in ~w[clay water]a
    end)
    |> case do
      nil ->
        new_meters =
          Enum.reduce((y + 1)..state.depth, state.meters, fn wet_y, meters ->
            Map.put(meters, {x, wet_y}, :wet)
          end)
        %__MODULE__{state | meters: new_meters, flow: flow}
      clay_y ->
        new_meters =
          Enum.reduce((y + 1)..(clay_y - 1), state.meters, fn wet_y, meters ->
            Map.put(meters, {x, wet_y}, :wet)
          end)
        %__MODULE__{
          state |
          meters: new_meters,
          flow: Enum.uniq([fill: {x, clay_y - 1}] ++ flow)
        }
    end
    |> fill
  end
  def fill(%__MODULE__{flow: [{:fill, {x, y}} | flow]} = state) do
    left_boundary =
      x
      |> Stream.iterate(fn new_x -> new_x - 1 end)
      |> Enum.find(fn new_x ->
        Map.get(state.meters, {new_x - 1, y}) == :clay or
          Map.get(state.meters, {new_x, y + 1}) in [nil, :wet]
      end)
    right_boundary =
      x
      |> Stream.iterate(fn new_x -> new_x + 1 end)
      |> Enum.find(fn new_x ->
        Map.get(state.meters, {new_x + 1, y}) == :clay or
          Map.get(state.meters, {new_x, y + 1}) in [nil, :wet]
      end)
    {spread, new_flow} =
      if Map.get(state.meters, {left_boundary, y + 1}) in [nil, :wet] or
           Map.get(state.meters, {right_boundary, y + 1}) in [nil, :wet] do
        drops =
          [left_boundary, right_boundary]
          |> Enum.filter(fn boundary_x ->
            Map.get(state.meters, {boundary_x, y + 1}) == nil
          end)
          |> Enum.map(fn boundary_x -> {:fall, {boundary_x, y}} end)
        {:wet, drops}
      else
        {:water, [fill: {x, y - 1}]}
      end
    new_meters =
      Enum.reduce(
        left_boundary..right_boundary,
        state.meters,
        fn new_x, meters ->
          Map.put(meters, {new_x, y}, spread)
        end
      )
    %__MODULE__{state | meters: new_meters, flow: Enum.uniq(new_flow ++ flow)}
    |> fill
  end

  def count(state, types) do
    state.meters
    |> dump_to_file(state)
    |> Map.values
    |> Enum.count(fn meter -> meter in types end)
  end

  defp parse_meters(line) do
    [single, start, finish] =
      Regex.scan(~r{\d+}, line)
      |> List.flatten
      |> Enum.map(&String.to_integer/1)
    cond do
      String.match?(line, ~r{\Ax=\d+,\s*y=\d+\.\.\d+\z}) ->
        for y <- start..finish, x = single do {x, y} end
      String.match?(line, ~r{\Ay=\d+,\s*x=\d+\.\.\d+\z}) ->
        for x <- start..finish, y = single do {x, y} end
      true ->
        raise "Unexpected input"
    end
  end
end

{options, [file]} =
  System.argv
  |> Enum.split_with(fn arg -> String.starts_with?(arg, "-") end)
reservoir =
  file
  |> File.stream!
  |> Stream.map(&String.trim/1)
  |> ReservoirResearch.parse
  |> ReservoirResearch.fill
if "-t" in options do
  ReservoirResearch.count(reservoir, ~w[water]a)
else
  ReservoirResearch.count(reservoir, ~w[wet water]a)
end
|> IO.puts
