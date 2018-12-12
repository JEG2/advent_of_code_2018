defmodule ChronalCharge do
  def power_level({x, y}, grid_serial_number) do
    rack_id = x + 10
    (rack_id * y + grid_serial_number) * rack_id
    |> to_string
    |> String.at(-3)
    |> Kernel.||("0")
    |> String.to_integer
    |> Kernel.-(5)
  end

  def summed_area_table(grid_serial_number) do
    Enum.reduce(1..300, Map.new, fn y, table ->
      Enum.reduce(1..300, table, fn x, new_table ->
        xy = {x, y}
        sum =
          power_level(xy, grid_serial_number)   +
          Map.get(new_table, {x,     y - 1}, 0) +
          Map.get(new_table, {x - 1, y},     0) -
          Map.get(new_table, {x - 1, y - 1}, 0)
        Map.put(new_table, xy, sum)
      end)
    end)
  end

  def max_area_total(summed_area_table, size) do
    offset = size - 1
    Enum.reduce(1..(300 - offset), nil, fn y, max ->
      Enum.reduce(1..(300 - offset), max, fn x, new_max ->
        area =
          {
            {x, y, size},
            Map.fetch!( summed_area_table, {x + offset, y + offset}    ) +
            Map.get(    summed_area_table, {x - 1,      y - 1},      0 ) -
            Map.get(    summed_area_table, {x + offset, y - 1},      0 ) -
            Map.get(    summed_area_table, {x - 1,      y + offset}, 0 )
          }
        if is_nil(new_max) or elem(area, 1) > elem(new_max, 1) do
          area
        else
          new_max
        end
      end)
    end)
  end

  def part_one do
    ChronalCharge.summed_area_table(3628)
    |> ChronalCharge.max_area_total(3)
    |> elem(0)
    |> Tuple.to_list
    |> Enum.take(2)
    |> Enum.join(",")
  end

  def part_two do
    table = ChronalCharge.summed_area_table(3628)
    Enum.reduce(1..300, nil, fn size, best ->
      area = ChronalCharge.max_area_total(table, size)
      if is_nil(best) or elem(area, 1) > elem(best, 1) do
        area
      else
        best
      end
    end)
    |> elem(0)
    |> Tuple.to_list
    |> Enum.join(",")
  end
end

result =
  if System.argv == ["-t"] do
    ChronalCharge.part_two
  else
    ChronalCharge.part_one
  end
IO.puts result
