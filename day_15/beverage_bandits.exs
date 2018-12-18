defmodule BeverageBandits do
  defmodule Unit do
    defstruct team: nil, location: nil, attack_power: 3, hp: 200

    def move(unit, enemies, map, blocked) do
      goals =
        enemies
        |> Enum.flat_map(fn enemy ->
          adjacent_squares(enemy.location, map, MapSet.new(blocked))
        end)
        |> Enum.uniq
      new_location =
        [[unit.location]]
        |> find_shortest_paths(MapSet.new([unit.location | blocked]), goals, map)
        |> select_best_path_and_move(unit.location)
      %__MODULE__{unit | location: new_location}
    end

    defp adjacent_squares({y, x}, map, blocked) do
      [
        {y - 1, x},
        {y + 1, x},
        {y, x - 1},
        {y, x + 1}
      ]
      |> Enum.filter(fn yx -> MapSet.member?(map, yx) end)
      |> Enum.reject(fn yx -> MapSet.member?(blocked, yx) end)
    end

    def find_shortest_paths([ ], _seen, _goals, _map), do: [ ]
    def find_shortest_paths(paths, seen, goals, map) do
      if Enum.any?(paths, fn [current | _previous] -> current in goals end) do
        paths
        |> Enum.filter(fn [current | _previous] -> current in goals end)
      else
        new_paths =
          paths
          |> Enum.flat_map(fn [current | _previous] = path ->
            current
            |> adjacent_squares(map, seen)
            |> Enum.map(fn next -> [next | path] end)
          end)
        new_seen =
          new_paths
          |> Enum.map(fn [current | _previous] -> current end)
          |> MapSet.new
        find_shortest_paths(new_paths, MapSet.union(seen, new_seen), goals, map)
      end
    end

    def select_best_path_and_move(paths, default) do
      selected_target =
        paths
        |> Enum.map(fn [target | _previous] -> target end)
        |> Enum.sort
        |> List.first
      paths
      |> Enum.filter(fn [target | _previous] -> target == selected_target end)
      |> Enum.map(fn path -> path |> Enum.reverse |> Enum.drop(1) end)
      |> Enum.map(fn [step | _next] -> step; [ ] -> default end)
      |> Enum.sort
      |> List.first
      |> Kernel.||(default)
    end

    def attack(unit, enemies, map) do
      enemies_by_location = Enum.into(enemies, Map.new, fn enemy ->
        {enemy.location, enemy}
      end)
      attacked =
        unit.location
        |> adjacent_squares(map, MapSet.new)
        |> Enum.filter(fn yx -> Map.has_key?(enemies_by_location, yx) end)
        |> Enum.sort_by(fn yx ->
          [enemies_by_location |> Map.fetch!(yx) |> Map.fetch!(:hp), yx]
        end)
        |> List.first
      {unit, attacked}
    end
  end

  defstruct map: MapSet.new, active_units: [ ], moved_units: [ ], round: 0

  def parse(lines) do
    lines
    |> Enum.with_index
    |> Enum.reduce(%__MODULE__{ }, fn {line, y}, state ->
      line
      |> String.trim
      |> String.graphemes
      |> Enum.with_index
      |> Enum.reduce(state, fn
        {square, x}, new_state when square in ~w[. G E] ->
          new_state
          |> parse_open_floor({y, x})
          |> parse_unit({y, x}, square)
        {_square, _x}, new_state ->
          new_state
      end)
    end)
  end

  defp parse_open_floor(state, yx) do
    %__MODULE__{state | map: MapSet.put(state.map, yx)}
  end

  defp parse_unit(state, yx, square) when square in ~w[G E] do
    unit = %Unit{team: square, location: yx}
    %__MODULE__{state | moved_units: [unit | state.moved_units]}
  end
  defp parse_unit(state, _yx, _square), do: state

  def finish_combat(state) do
    state
    |> Stream.iterate(fn new_state -> take_unit_turn(new_state) end)
    |> Enum.find(fn new_state -> finished?(new_state) end)
    |> determine_outcome
  end

  defp take_unit_turn(%__MODULE__{active_units: [ ]} = state) do
    %__MODULE__{
      state |
      active_units: Enum.sort_by(state.moved_units, &(&1.location)),
      moved_units: [ ],
      round: state.round + 1
    }
    |> take_unit_turn
  end
  defp take_unit_turn(
    %__MODULE__{active_units: [unit | new_active_units]} = state
  ) do
    units = new_active_units ++ state.moved_units
    enemies = Enum.filter(units, fn other -> other.team != unit.team end)
    blocked = Enum.map(units, fn other -> other.location end)
    {new_unit, attacked} =
      unit
      |> Unit.move(enemies, state.map, blocked)
      |> Unit.attack(enemies, state.map)
    %__MODULE__{
      state |
      active_units: hurt_enemy(new_active_units, attacked, unit.attack_power),
      moved_units: [ new_unit |
                     hurt_enemy(state.moved_units, attacked, unit.attack_power) ]
    }
  end

  defp hurt_enemy(units, yx, attack_power) do
    units
    |> Enum.map(fn unit ->
      if unit.location == yx do
        %Unit{unit | hp: unit.hp - attack_power}
      else
        unit
      end
    end)
    |> Enum.reject(fn unit -> unit.hp <= 0 end)
  end

  defp finished?(state) do
    state.active_units ++ state.moved_units
    |> Enum.map(fn unit -> unit.team end)
    |> Enum.uniq
    |> length
    |> Kernel.==(1)
  end

  defp determine_outcome(state) do
    hp_sum =
      state.active_units ++ state.moved_units
      |> Enum.map(fn unit -> unit.hp end)
      |> Enum.sum
    if state.active_units == [ ] do
      hp_sum * state.round
    else
      hp_sum * (state.round - 1)
    end
  end

  def find_elf_win(state) do
    starting_elves = Enum.count(state.moved_units, fn unit ->
      unit.team == "E"
    end)
    200..4
    |> Stream.map(fn attack_power ->
      %__MODULE__{
        state |
        moved_units: Enum.map(state.moved_units, fn unit ->
          if unit.team == "E" do
            %Unit{unit | attack_power: attack_power}
          else
            unit
          end
        end)
      }
      |> Stream.iterate(fn new_state -> take_unit_turn(new_state) end)
      |> Enum.find(fn new_state ->
        elf_died?(new_state, starting_elves) or finished?(new_state)
      end)
    end)
    |> Stream.chunk_every(2, 1)
    |> Enum.find(fn [_previous_state, new_state] ->
      elf_died?(new_state, starting_elves)
    end)
    |> hd
    |> determine_outcome
  end

  defp elf_died?(state, starting_elves) do
    state.active_units ++ state.moved_units
    |> Enum.count(fn unit -> unit.team == "E" end)
    |> Kernel.<(starting_elves)
  end
end

{options, [file]} =
  System.argv
  |> Enum.split_with(fn arg -> arg == "-t" end)
combat =
  file
  |> File.stream!
  |> BeverageBandits.parse
if "-t" in options do
  BeverageBandits.find_elf_win(combat)
else
  BeverageBandits.finish_combat(combat)
end
|> IO.puts
