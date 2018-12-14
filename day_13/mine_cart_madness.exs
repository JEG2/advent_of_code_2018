defmodule MineCartMadness do
  defstruct tracks: Map.new, carts: [ ], moved: [ ]

  defmodule Cart do
    defstruct facing: nil, location: nil, turns: ~w[left straight right]a

    def new("<", location) do
      %__MODULE__{facing: :left, location: location}
    end
    def new(">", location) do
      %__MODULE__{facing: :right, location: location}
    end
    def new("^", location) do
      %__MODULE__{facing: :up, location: location}
    end
    def new("v", location) do
      %__MODULE__{facing: :down, location: location}
    end

    def move(cart, tracks) do
      from = Map.fetch!(tracks, cart.location)
      new_location = Map.fetch!(from, cart.facing)
      to = Map.fetch!(tracks, new_location)
      {new_facing, new_turns} = turn(cart, to.type)
      %__MODULE__{cart | facing: new_facing, turns: new_turns, location: new_location}
    end

    def turn(%__MODULE__{facing: :up} = cart, :forward_curve), do: {:right, cart.turns}
    def turn(%__MODULE__{facing: :down} = cart, :forward_curve), do: {:left, cart.turns}
    def turn(%__MODULE__{facing: :left} = cart, :forward_curve), do: {:down, cart.turns}
    def turn(%__MODULE__{facing: :right} = cart, :forward_curve), do: {:up, cart.turns}
    def turn(%__MODULE__{facing: :up} = cart, :back_curve), do: {:left, cart.turns}
    def turn(%__MODULE__{facing: :down} = cart, :back_curve), do: {:right, cart.turns}
    def turn(%__MODULE__{facing: :left} = cart, :back_curve), do: {:up, cart.turns}
    def turn(%__MODULE__{facing: :right} = cart, :back_curve), do: {:down, cart.turns}
    def turn(%__MODULE__{facing: :up, turns: [:left | turns]}, :intersection), do: {:left, turns ++ [:left]}
    def turn(%__MODULE__{facing: :down, turns: [:left | turns]}, :intersection), do: {:right, turns ++ [:left]}
    def turn(%__MODULE__{facing: :left, turns: [:left | turns]}, :intersection), do: {:down, turns ++ [:left]}
    def turn(%__MODULE__{facing: :right, turns: [:left | turns]}, :intersection), do: {:up, turns ++ [:left]}
    def turn(%__MODULE__{facing: :up, turns: [:right | turns]}, :intersection), do: {:right, turns ++ [:right]}
    def turn(%__MODULE__{facing: :down, turns: [:right | turns]}, :intersection), do: {:left, turns ++ [:right]}
    def turn(%__MODULE__{facing: :left, turns: [:right | turns]}, :intersection), do: {:up, turns ++ [:right]}
    def turn(%__MODULE__{facing: :right, turns: [:right | turns]}, :intersection), do: {:down, turns ++ [:right]}
    def turn(%__MODULE__{facing: facing, turns: [:straight | turns]}, :intersection), do: {facing, turns ++ [:straight]}
    def turn(%__MODULE__{facing: facing, turns: turns}, _type), do: {facing, turns}
  end

  defmodule Track do
    defstruct ~w[type up down left right]a

    def new("-", {x, y}) do
      %__MODULE__{type: :horizontal, left: {x - 1, y}, right: {x + 1, y}}
    end
    def new("<", xy), do: new("-", xy)
    def new(">", xy), do: new("-", xy)
    def new("|", {x, y}) do
      %__MODULE__{type: :vertical, up: {x, y - 1}, down: {x, y + 1}}
    end
    def new("^", xy), do: new("|", xy)
    def new("v", xy), do: new("|", xy)
    def new("/", {x, y}) do
      %__MODULE__{type: :forward_curve, up: {x, y - 1}, down: {x, y + 1}, left: {x - 1, y}, right: {x + 1, y}}
    end
    def new("\\", {x, y}) do
      %__MODULE__{type: :back_curve, up: {x, y - 1}, down: {x, y + 1}, left: {x - 1, y}, right: {x + 1, y}}
    end
    def new("+", {x, y}) do
      %__MODULE__{type: :intersection, up: {x, y - 1}, down: {x, y + 1}, left: {x - 1, y}, right: {x + 1, y}}
    end
  end

  def parse(lines) do
    lines
    |> Enum.with_index
    |> Enum.reduce(%__MODULE__{ }, fn {line, y}, state ->
      line
      |> String.graphemes
      |> Enum.with_index
      |> Enum.reduce(state, fn {symbol, x}, new_state ->
        xy = {x, y}
        new_state
        |> parse_track(symbol, xy)
        |> parse_cart(symbol, xy)
      end)
    end)
  end

  def find_first_crash(state) do
    state
    |> Stream.iterate(&move_next_cart/1)
    |> Enum.find(&crash?/1)
    |> Map.fetch!(:moved)
    |> hd
    |> Map.fetch!(:location)
    |> Tuple.to_list
    |> Enum.join(",")
  end

  def find_last_cart(state) do
    state
    |> Stream.iterate(fn new_state -> new_state |> remove_crash |> move_next_cart end)
    |> Enum.find(fn new_state -> new_state.carts == [ ] and length(new_state.moved) == 1 end)
    |> Map.fetch!(:moved)
    |> hd
    |> Map.fetch!(:location)
    |> Tuple.to_list
    |> Enum.join(",")
  end

  defp move_next_cart(%__MODULE__{carts: [ ]} = state) do
    %__MODULE__{
      state |
      carts: Enum.sort_by(state.moved, fn %Cart{location: {x, y}} -> [y, x] end),
      moved: [ ]
    }
    |> move_next_cart
  end
  defp move_next_cart(%__MODULE__{carts: [cart | carts]} = state) do
    %__MODULE__{
      state |
      carts: carts,
      moved: [Cart.move(cart, state.tracks) | state.moved]
    }
  end

  defp crash?(%__MODULE__{moved: [current | moved]} = state) do
    state.carts ++ moved
    |> Enum.map(fn cart -> cart.location end)
    |> Enum.find(fn xy -> xy == current.location end)
  end

  defp remove_crash(state) do
    if crash?(state) do
      %__MODULE__{
        state |
        moved: Enum.reject(state.moved, fn cart -> cart.location == hd(state.moved).location end),
        carts: Enum.reject(state.carts, fn cart -> cart.location == hd(state.moved).location end)
      }
    else
      state
    end
  end

  defp parse_track(state, track, xy) when track in ~w[- | / \\ + < > ^ v] do
    %__MODULE__{state | tracks: Map.put(state.tracks, xy, Track.new(track, xy))}
  end
  defp parse_track(state, _track, _xy), do: state

  defp parse_cart(state, cart, xy) when cart in ~w[< > ^ v] do
    %__MODULE__{state | moved: [Cart.new(cart, xy) | state.moved]}
  end
  defp parse_cart(state, _cart, _xy), do: state
end

{options, [file]} =
  System.argv
  |> Enum.split_with(fn arg -> arg == "-t" end)
mine =
  file
  |> File.stream!
  |> MineCartMadness.parse
if options == ["-t"] do
  MineCartMadness.find_last_cart(mine)
else
  MineCartMadness.find_first_crash(mine)
end
|> IO.puts
