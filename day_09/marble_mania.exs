defmodule MarbleMania do
  defstruct players: nil,
            last_play: nil,
            circle: %{0 => {0, 0}},
            turn: 1,
            current_marble: 0,
            player: 1,
            scores: Map.new

  def init(stream) do
    {Enum.to_list(stream), %__MODULE__{ }}
  end

  def process(game, state) do
    state
    |> define_game(game)
    |> play_game
  end

  defp define_game(state, game) do
    [players, last_play] =
      Regex.scan(~r{\d+}, game)
      |> List.flatten
      |> Enum.map(&String.to_integer/1)
    %__MODULE__{state | players: players, last_play: last_play}
  end

  defp play_game(%__MODULE__{last_play: last_play, turn: turn} = state) when turn - 1 == last_play do
    state.scores
    |> Map.values
    |> Enum.max
  end
  defp play_game(state) do
    state
    |> play_turn
    |> play_game
  end

  defp play_turn(%__MODULE__{turn: turn} = state) when rem(turn, 23) == 0 do
    removed_marble =
      state.current_marble
      |> Stream.iterate(fn current -> state.circle |> Map.fetch!(current) |> elem(0) end)
      |> Stream.drop(1)
      |> Enum.take(7)
      |> List.last
    {one_counter_clockwise, one_clockwise} = Map.fetch!(state.circle, removed_marble)
    new_circle =
      state.circle
      |> Map.update!(one_counter_clockwise, &{elem(&1, 0), one_clockwise})
      |> Map.update!(one_clockwise, &{one_counter_clockwise, elem(&1, 1)})
    score = state.turn + removed_marble
    %__MODULE__{
      state |
      circle: new_circle,
      current_marble: one_clockwise,
      turn: state.turn + 1,
      player: (if state.player == state.players, do: 1, else: state.player + 1),
      scores: Map.update(state.scores, state.player, score, &(&1 + score))
    }
  end
  defp play_turn(state) do
    {_one_counter_clockwise, one_clockwise} = Map.fetch!(state.circle, state.current_marble)
    two_clockwise = state.circle |> Map.fetch!(one_clockwise) |> elem(1)
    new_circle =
      state.circle
      |> Map.update!(one_clockwise, &{elem(&1, 0), state.turn})
      |> Map.put(state.turn, {one_clockwise, two_clockwise})
      |> Map.update!(two_clockwise, &{state.turn, elem(&1, 1)})
    %__MODULE__{
      state |
      circle: new_circle,
      current_marble: state.turn,
      turn: state.turn + 1,
      player: (if state.player == state.players, do: 1, else: state.player + 1)
    }
  end
end

defmodule MarbleManiaPartTwo do
  def init(stream) do
    {[game], state} = MarbleMania.init(stream)
    {
      [ Regex.replace(~r{(\d+)\s+points}, game, fn _match, n ->
        n |> String.to_integer |> Kernel.*(100) |> to_string
      end) ],
      state
    }
  end

  defdelegate process(game, state), to: MarbleMania
end

Code.require_file "../advent_of_code.exs", __DIR__
AdventOfCode.process_file(
  MarbleMania,
  MarbleManiaPartTwo,
  System.argv
)
