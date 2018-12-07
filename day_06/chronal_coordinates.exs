defmodule ChronalCoordinates do
  defmodule Coordinate do
    defstruct ~w[xy tests]a

    def new(x, y) do
      xy = {x, y}
      %__MODULE__{xy: xy, tests: near(xy)}
    end

    def expand(%__MODULE__{ } = coord, grid, dangers) do
      new_grid = Enum.reduce(coord.tests, grid, fn from, g ->
        distances = Enum.into(dangers, Map.new, fn to ->
          {to, distance(from, to)}
        end)
        closest = distances |> Map.values |> Enum.min
        winner =
          case Enum.filter(distances, fn {_to, len} -> len == closest end) do
            [{to, _len}] ->
              to
            _multiple ->
              :shared
          end
        Map.put(g, from, winner)
      end)
      new_tests =
        coord.tests
        |> Enum.filter(fn test -> Map.fetch!(new_grid, test) == coord.xy end)
        |> Enum.reduce(MapSet.new, fn test, nearby ->
          test
          |> near
          |> MapSet.difference(MapSet.new(Map.keys(new_grid)))
          |> MapSet.union(nearby)
        end)
      {%__MODULE__{coord | tests: new_tests}, new_grid}
    end

    def done?(%__MODULE__{tests: tests}), do: MapSet.size(tests) == 0
    def done?(_coord), do: false

    defp near({x, y}) do
      [ {x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1},
        {x - 1, y},                 {x + 1, y},
        {x - 1, y + 1}, {x, y + 1}, {x + 1, y + 1} ]
      |> MapSet.new
    end

    defp distance({from_x, from_y}, {to_x, to_y}) do
      abs(from_x - to_x) + abs(from_y - to_y)
    end
  end

  defstruct coords: [ ], grid: Map.new

  def init(stream) do
    {stream, %__MODULE__{ }}
  end

  def process(coord, state) do
    [x, y] =
      Regex.scan(~r{\d+}, coord, capture: :first)
      |> List.flatten
      |> Enum.map(&String.to_integer/1)
    %__MODULE__{state | coords: [Coordinate.new(x, y) | state.coords]}
  end

  def answer(state) do
    dangers = Enum.map(state.coords, fn coord -> coord.xy end)
    expand_repeatedly(state, dangers)
  end

  defp expand_repeatedly(state, dangers) do
    state
    |> expand_all_once(dangers)
    |> expand_repeatedly(dangers)
  end

  defp expand_all_once(state, dangers) do
    state.coords
    |> Enum.with_index
    |> Enum.reject(fn {coord, _i} -> Coordinate.done?(coord) end)
    |> Enum.reduce(state, fn {coord, i}, s ->
      {new_coord, new_grid} = expand_once(coord, s.grid, dangers)
      %__MODULE__{
        s |
        coords: List.replace_at(s.coords, i, new_coord),
        grid: new_grid
      }
    end)
  end

  defp expand_once(coord, grid, dangers) do
    {new_coord, new_grid} = Coordinate.expand(coord, grid, dangers)
    if Coordinate.done?(new_coord) do
      Enum.count(new_grid, fn {_xy, winner} -> winner == new_coord.xy end)
      |> IO.puts
    end
    {new_coord, new_grid}
  end
end

defmodule ChronalCoordinatesPartTwo do
  defstruct coords: [ ]

  def init(stream) do
    {stream, %__MODULE__{ }}
  end

  def process(coord, state) do
    [x, y] =
      Regex.scan(~r{\d+}, coord, capture: :first)
      |> List.flatten
      |> Enum.map(&String.to_integer/1)
    %__MODULE__{state | coords: [{x, y} | state.coords]}
  end

  def answer(state) do
    lowest_x = state.coords |> Enum.map(fn {x, _y} -> x end) |> Enum.min
    highest_x = state.coords |> Enum.map(fn {x, _y} -> x end) |> Enum.max
    lowest_y = state.coords |> Enum.map(fn {_x, y} -> y end) |> Enum.min
    highest_y = state.coords |> Enum.map(fn {_x, y} -> y end) |> Enum.max
    start =
      Enum.find_value(lowest_y..highest_y, fn y ->
        x =
          Enum.find(lowest_x..highest_x, fn x ->
            safe?({x, y}, state.coords)
          end)
        x && {x, y}
      end)

    expand([start], state.coords, MapSet.new([start]))
    |> Enum.count
  end

  defp safe?(from, safe_places) do
    safe_places
    |> Enum.map(fn to -> distance(from, to) end)
    |> Enum.sum
    |> Kernel.<(10_000)
  end

  defp expand([ ], _safe_places, region), do: region
  defp expand(xys, safe_places, region) do
    next =
      xys
      |> Enum.flat_map(fn xy -> near(xy) end)
      |> Enum.uniq
      |> Enum.reject(fn xy -> MapSet.member?(region, xy) end)
    safe = Enum.filter(next, fn xy -> safe?(xy, safe_places) end)
    expand(safe, safe_places, MapSet.union(region, MapSet.new(safe)))
  end

  defp distance({from_x, from_y}, {to_x, to_y}) do
    abs(from_x - to_x) + abs(from_y - to_y)
  end

  defp near({x, y}) do
    [ {x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1},
      {x - 1, y},                 {x + 1, y},
      {x - 1, y + 1}, {x, y + 1}, {x + 1, y + 1} ]
    |> MapSet.new
  end
end

Code.require_file "../advent_of_code.exs", __DIR__
AdventOfCode.process_file(
  ChronalCoordinates,
  ChronalCoordinatesPartTwo,
  System.argv
)
