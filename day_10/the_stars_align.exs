defmodule TheStarsAlign do
  defmodule Star do
    defstruct ~w[x y x_velocity y_velocity]a
  end

  defstruct stars: [ ], bounding_box: nil, expanding: false, seconds: 0

  def init(stream) do
    {stream, %__MODULE__{ }}
  end

  def process(star, state) do
    [x, y, x_velocity, y_velocity] =
      Regex.run(
        ~r{\Aposition=<\s*(-?\d+),\s*(-?\d+)>\s+velocity=<\s*(-?\d+),\s*(-?\d+)>\z},
        star,
        capture: :all_but_first
      )
      |> Enum.map(&String.to_integer/1)
    %__MODULE__{
      state |
      stars: [
        %Star{x: x, y: y, x_velocity: x_velocity, y_velocity: y_velocity} |
        state.stars
      ]
    }
  end

  def answer(state) do
    state
    |> wait_for_message
    |> view_sky
  end

  def wait_for_message(state) do
    case pass_one_second(state) do
      %__MODULE__{expanding: true} ->
        state
      new_state ->
        wait_for_message(new_state)
    end
  end

  defp pass_one_second(state) do
    new_stars = Enum.map(state.stars, fn star ->
      %Star{star | x: star.x + star.x_velocity, y: star.y + star.y_velocity}
    end)
    {low_x, high_x} = new_stars |> Enum.map(fn star -> star.x end) |> Enum.min_max
    {low_y, high_y} = new_stars |> Enum.map(fn star -> star.y end) |> Enum.min_max
    new_bounding_box = {low_x..high_x, low_y..high_y}
    expanding? = size_of(new_bounding_box) > size_of(state.bounding_box)
    %__MODULE__{
      state |
      stars: new_stars,
      bounding_box: new_bounding_box,
      expanding: expanding?,
      seconds: state.seconds + 1
    }
  end

  defp view_sky(state) do
    by_position = Enum.group_by(state.stars, fn star -> {star.x, star.y} end)
    state.bounding_box
    |> elem(1)
    |> Enum.map(fn y ->
      state.bounding_box
      |> elem(0)
      |> Enum.reduce("", fn x, row ->
        row <>
          case by_position[{x, y}] do
            stars when is_list(stars) ->
              "#"
            nil ->
              "."
          end
      end)
    end)
    |> Enum.join("\n")
  end

  defp size_of(nil), do: :infinity
  defp size_of({xs, ys}) do
    (xs.last - xs.first) * (ys.last - ys.first)
  end
end

defmodule TheStarsAlignPartTwo do
  defdelegate init(stream), to: TheStarsAlign
  defdelegate process(star, state), to: TheStarsAlign

  def answer(state) do
    state
    |> TheStarsAlign.wait_for_message
    |> Map.fetch!(:seconds)
  end
end

Code.require_file "../advent_of_code.exs", __DIR__
AdventOfCode.process_file(
  TheStarsAlign,
  TheStarsAlignPartTwo,
  System.argv
)
