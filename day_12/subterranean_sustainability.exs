defmodule SubterraneanSustainability do
  defstruct pots: nil, notes: MapSet.new

  def init(stream) do
    {stream, %__MODULE__{ }}
  end

  def process(<<"initial state: ", rest::binary>>, state) do
    new_pots =
      rest
      |> String.graphemes
      |> Enum.with_index
      |> Enum.filter(&match?({"#", _i}, &1))
      |> Enum.reduce(MapSet.new, fn {"#", i}, pots -> MapSet.put(pots, i) end)
    %__MODULE__{state | pots: new_pots}
  end
  def process(line, state) do
    if String.match?(line, ~r|\A[\.#]{5}\s+=>\s+#\z|) do
      note = line |> String.slice(0..4) |> String.graphemes
      %__MODULE__{state | notes: MapSet.put(state.notes, note)}
    else
      state
    end
  end

  def answer(state) do
    state
    |> pass_20_generations
    |> count_plants
  end

  def pass_generation(state) do
    {leftmost, rightmost} = Enum.min_max(state.pots)
    new_pots =
      (leftmost - 4)..(rightmost + 4)
      |> Enum.chunk_every(5, 1, :discard)
      |> Enum.filter(fn indices ->
        plants = Enum.map(indices, fn i ->
          if MapSet.member?(state.pots, i), do: "#", else: "."
        end)
        MapSet.member?(state.notes, plants)
      end)
      |> Enum.map(fn indices -> Enum.at(indices, 2) end)
      |> MapSet.new
    %__MODULE__{state | pots: new_pots}
  end

  defp pass_20_generations(state) do
    Enum.reduce(1..20, state, fn _i, new_state -> pass_generation(new_state) end)
  end

  def count_plants(state) do
    Enum.sum(state.pots)
  end
end

defmodule SubterraneanSustainabilityPartTwo do
  import SubterraneanSustainability, only: [pass_generation: 1, count_plants: 1]

  defdelegate init(stream), to: SubterraneanSustainability
  defdelegate process(line, state), to: SubterraneanSustainability

  def answer(state) do
    find_stability(state)
  end

  defp find_stability(state) do
    Enum.reduce_while(
      1..50_000_000_000,
      {state, 0, [ ]},
      fn i, {new_state, prev_count, differences} ->
        next_generation = pass_generation(new_state)
        count = count_plants(next_generation)
        difference = count - prev_count
        new_differences = [difference | differences]
        if length(new_differences) < 10 do
          {:cont, {next_generation, count, new_differences}}
        else
          case Enum.uniq(new_differences) do
            [n] ->
              {:halt, (50_000_000_000 - i) * n + count}
            _not_stable ->
              {:cont, {next_generation, count, Enum.take(new_differences, 10)}}
          end
        end
      end
    )
  end
end

Code.require_file "../advent_of_code.exs", __DIR__
AdventOfCode.process_file(
  SubterraneanSustainability,
  SubterraneanSustainabilityPartTwo,
  System.argv
)
