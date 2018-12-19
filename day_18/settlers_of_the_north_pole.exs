defmodule SettlersOfTheNorthPole do
  defstruct ~w[acres neighbors]a

  def parse(lines) do
    new_acres =
      lines
      |> Stream.with_index
      |> Enum.reduce(Map.new, fn {line, y}, acres ->
        line
        |> String.graphemes
        |> Enum.with_index
        |> Enum.reduce(acres, fn {acre, x}, acres ->
          Map.put(acres, {x, y}, acre)
        end)
      end)
    new_neighbors =
      new_acres
      |> Map.keys
      |> Enum.into(Map.new, fn {x, y} ->
        neighbors =
          [ {x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1},
            {x - 1, y},                 {x + 1, y},
            {x - 1, y + 1}, {x, y + 1}, {x + 1, y + 1} ]
          |> Enum.filter(fn xy -> Map.has_key?(new_acres, xy) end)
        {{x, y}, neighbors}
      end)
    %__MODULE__{acres: new_acres, neighbors: new_neighbors}
  end

  def pass_minutes(state, 0), do: state
  def pass_minutes(state, count) do
    state
    |> pass_minute
    |> pass_minutes(count - 1)
  end

  def pass_many_minutes(state, count) do
    {new_state, start, cycle} = find_cycle(state, count)
    pass_minutes(new_state, rem(count - start, cycle - start))
  end

  def count_wood(state) do
    counts =
      state.acres
      |> Map.values
      |> Enum.reduce(Map.new, fn acre, counts ->
        Map.update(counts, acre, 1, &(&1 + 1))
      end)
    Map.fetch!(counts, "|") * Map.fetch!(counts, "#")
  end

  defp pass_minute(state) do
    new_acres =
      Enum.into(state.acres, Map.new, fn {xy, contents} ->
        neighbors =
          state.neighbors
          |> Map.fetch!(xy)
          |> Enum.map(fn neighbor -> Map.fetch!(state.acres, neighbor) end)
        new_contents =
          case contents do
            "." ->
              if Enum.count(neighbors, fn other -> other == "|" end) >= 3 do
                "|"
              else
                "."
              end
            "|" ->
              if Enum.count(neighbors, fn other -> other == "#" end) >= 3 do
                "#"
              else
                "|"
              end
            "#" ->
              if Enum.count(neighbors, fn other -> other == "#" end) >= 1 and
                 Enum.count(neighbors, fn other -> other == "|" end) >= 1 do
                "#"
              else
                "."
              end
          end
        {xy, new_contents}
      end)
    %__MODULE__{state | acres: new_acres}
  end

  def find_cycle(state, count) do
    Enum.reduce_while(
      1..count,
      {state, %{state => 0}},
      fn minute, {previous_state, states} ->
        new_state = pass_minute(previous_state)
        if Map.has_key?(states, new_state) do
          {:halt, {new_state, Map.fetch!(states, new_state), minute}}
        else
          {:cont, {new_state, Map.put(states, new_state, minute)}}
        end
      end
    )
  end
end

{options, [file]} =
  System.argv
  |> Enum.split_with(fn arg -> String.starts_with?(arg, "-") end)
north_pole =
  file
  |> File.stream!
  |> Stream.map(&String.trim/1)
  |> SettlersOfTheNorthPole.parse
if "-t" in options do
  north_pole
  |> SettlersOfTheNorthPole.pass_many_minutes(1_000_000_000)
  |> SettlersOfTheNorthPole.count_wood
else
  north_pole
  |> SettlersOfTheNorthPole.pass_minutes(10)
  |> SettlersOfTheNorthPole.count_wood
end
|> IO.puts
