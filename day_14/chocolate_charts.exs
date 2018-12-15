defmodule ChocolateCharts do
  defmodule Ring do
    defstruct size: 0

    def new do
      :ets.new(:ring, ~w[set private named_table]a)
      %__MODULE__{ }
    end
    def new(enum), do: push_all(new(), enum)

    def fetch!(_ring, i) do
      [{^i, item}] = :ets.lookup(:ring, i)
      item
    end

    def push_all(ring, items) do
      Enum.reduce(items, ring, fn item, new_ring -> push(new_ring, item) end)
    end

    def push(ring, item) do
      :ets.insert(:ring, {ring.size, item})
      %__MODULE__{ring | size: ring.size + 1}
    end

    def wrap_index(ring, i, offset) do
      rem(i + offset, ring.size)
    end

    def slice(ring, indices) do
      Enum.map(indices, fn i -> fetch!(ring, i) end)
    end
  end

  @desired_recipes 10

  defstruct recipes: Ring.new([3, 7]), elves: [0, 1], goal: nil, goal_size: nil

  def new(goal), do: %__MODULE__{goal: goal, goal_size: (if is_list(goal), do: length(goal))}

  def practice_recipes(state) do
    new_state = make_recipes(state)
    if done_practicing?(new_state) do
      best_recipes(new_state)
    else
      practice_recipes(new_state)
    end
  end

  def find_goal(state) do
    new_state = make_recipes(state)
    case count_to_goal(new_state) do
      count when is_integer(count) ->
        count
      nil ->
        find_goal(new_state)
    end
  end

  def make_recipes(state) do
    current_recipes =
      state.elves
      |> Enum.map(fn i -> Ring.fetch!(state.recipes, i) end)
    added_recipes =
      current_recipes
      |> Enum.sum
      |> to_string
      |> String.graphemes
      |> Enum.map(fn n -> String.to_integer(n) end)
    new_recipes = Ring.push_all(state.recipes, added_recipes)
    new_elves =
      state.elves
      |> Enum.zip(current_recipes)
      |> Enum.map(fn {elf, recipe} ->
        Ring.wrap_index(new_recipes, elf, recipe + 1)
      end)
    %__MODULE__{state | recipes: new_recipes, elves: new_elves}
  end

  def done_practicing?(state) do
    state.recipes.size >= state.goal + @desired_recipes
  end

  def best_recipes(state) do
    state.recipes
    |> Ring.slice(state.goal..(state.goal + @desired_recipes - 1))
    |> Enum.join
  end

  def count_to_goal(state) do
    last_index = state.recipes.size - 1
    count = state.recipes.size - state.goal_size
    cond do
      state.recipes.size >= state.goal_size and
      Ring.slice(state.recipes, count..last_index) == state.goal ->
        count
      state.recipes.size > state.goal_size and
      Ring.slice(state.recipes, (count - 1)..(last_index - 1)) == state.goal ->
        count - 1
      true ->
        nil
    end
  end
end

{options, goal} =
  System.argv
  |> Enum.split_with(fn arg -> arg == "-t" end)
if "-t" in options do
  goal
  |> hd
  |> String.graphemes
  |> Enum.map(fn n -> String.to_integer(n) end)
  |> ChocolateCharts.new
  |> ChocolateCharts.find_goal
else
  goal
  |> hd
  |> String.to_integer
  |> ChocolateCharts.new
  |> ChocolateCharts.practice_recipes
end
|> IO.puts
