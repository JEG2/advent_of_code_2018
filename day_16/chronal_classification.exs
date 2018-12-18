defmodule ChronalClassification do
  use Bitwise, only_operators: true

  @opcodes ~w[
    addr
    addi
    mulr
    muli
    banr
    bani
    borr
    bori
    setr
    seti
    gtir
    gtri
    gtrr
    eqir
    eqri
    eqrr
  ]a

  def parse(lines) do
    lines
    |> Stream.chunk_every(4)
    |> Stream.map(fn sample -> Enum.take(sample, 3) end)
    |> Stream.take_while(&match?([<<"Before:", _chars::binary>> | _lines], &1))
    |> Stream.map(fn sample ->
      Enum.map(sample, fn line ->
        Regex.scan(~r{\d+}, line, capture: :first)
        |> List.flatten
        |> Enum.map(fn n -> String.to_integer(n) end)
      end)
    end)
  end

  def count_sample_behaviors(samples) do
    Enum.count(samples, fn [start, [_n, input_a, input_b, output_c], finish] ->
      registers = to_registers(start)
      @opcodes
      |> Enum.count(fn opcode ->
        apply(
          __MODULE__,
          opcode,
          [input_a, input_b, output_c, registers]
        ) == to_registers(finish)
      end)
      |> Kernel.>=(3)
    end)
  end

  def determine_opcode_numbers(samples) do
    samples
    |> Enum.reduce(Map.new, fn [start, [n, input_a, input_b, output_c], finish], mapping ->
      registers = to_registers(start)
      matches =
        @opcodes
        |> Enum.filter(fn opcode ->
          apply(
            __MODULE__,
            opcode,
            [input_a, input_b, output_c, registers]
          ) == to_registers(finish)
        end)
        |> MapSet.new
      Map.update(mapping, n, matches, &MapSet.intersection(&1, matches))
    end)
    |> narrow_mapping
  end

  def execute_program(mapping, file) do
    file
    |> File.read!
    |> String.split("\n\n\n\n")
    |> List.last
    |> String.split("\n", trim: true)
    |> Stream.map(fn line -> line |> String.split(" ") |> Enum.map(&String.to_integer/1) end)
    |> Enum.reduce(to_registers([0, 0, 0, 0]), fn [n | args], registers ->
      apply(__MODULE__, Map.fetch!(mapping, n), args ++ [registers])
    end)
    |> Map.fetch!(0)
  end

  defp narrow_mapping(mapping) do
    mapped =
      mapping
      |> Map.values
      |> Enum.filter(fn opcodes -> MapSet.size(opcodes) == 1 end)
      |> Enum.reduce(MapSet.new, fn opcodes, combined -> MapSet.union(combined, opcodes) end)
    new_mapping =
      Enum.into(mapping, Map.new, fn {n, opcodes} ->
        if MapSet.size(opcodes) > 1 do
          {n, MapSet.difference(opcodes, mapped)}
        else
          {n, opcodes}
        end
      end)
    if Enum.all?(new_mapping, fn {_n, opcodes} -> MapSet.size(opcodes) == 1 end) do
      Enum.into(new_mapping, Map.new, fn {n, opcodes} -> {n, opcodes |> MapSet.to_list |> hd} end)
    else
      narrow_mapping(new_mapping)
    end
  end

  defp to_registers(values) do
    values
    |> Enum.with_index
    |> Enum.into(Map.new, fn {value, i} -> {i, value} end)
  end

  def addr(input_a, input_b, output_c, registers) do
    value = register(registers, input_a) + register(registers, input_b)
    write_register(registers, output_c, value)
  end

  def addi(input_a, input_b, output_c, registers) do
    value = register(registers, input_a) + input_b
    write_register(registers, output_c, value)
  end

  def mulr(input_a, input_b, output_c, registers) do
    value = register(registers, input_a) * register(registers, input_b)
    write_register(registers, output_c, value)
  end

  def muli(input_a, input_b, output_c, registers) do
    value = register(registers, input_a) * input_b
    write_register(registers, output_c, value)
  end

  def banr(input_a, input_b, output_c, registers) do
    value = register(registers, input_a) &&& register(registers, input_b)
    write_register(registers, output_c, value)
  end

  def bani(input_a, input_b, output_c, registers) do
    value = register(registers, input_a) &&& input_b
    write_register(registers, output_c, value)
  end

  def borr(input_a, input_b, output_c, registers) do
    value = register(registers, input_a) ||| register(registers, input_b)
    write_register(registers, output_c, value)
  end

  def bori(input_a, input_b, output_c, registers) do
    value = register(registers, input_a) ||| input_b
    write_register(registers, output_c, value)
  end

  def setr(input_a, _input_b, output_c, registers) do
    value = register(registers, input_a)
    write_register(registers, output_c, value)
  end

  def seti(input_a, _input_b, output_c, registers) do
    value = input_a
    write_register(registers, output_c, value)
  end

  def gtir(input_a, input_b, output_c, registers) do
    value =
      if input_a > register(registers, input_b) do
        1
      else
        0
      end
    write_register(registers, output_c, value)
  end

  def gtri(input_a, input_b, output_c, registers) do
    value =
      if register(registers, input_a) > input_b do
        1
      else
        0
      end
    write_register(registers, output_c, value)
  end

  def gtrr(input_a, input_b, output_c, registers) do
    value =
      if register(registers, input_a) > register(registers, input_b) do
        1
      else
        0
      end
    write_register(registers, output_c, value)
  end

  def eqir(input_a, input_b, output_c, registers) do
    value =
      if input_a == register(registers, input_b) do
        1
      else
        0
      end
    write_register(registers, output_c, value)
  end

  def eqri(input_a, input_b, output_c, registers) do
    value =
      if register(registers, input_a) == input_b do
        1
      else
        0
      end
    write_register(registers, output_c, value)
  end

  def eqrr(input_a, input_b, output_c, registers) do
    value =
      if register(registers, input_a) == register(registers, input_b) do
        1
      else
        0
      end
    write_register(registers, output_c, value)
  end

  defp register(registers, n), do: Map.fetch!(registers, n)
  defp write_register(registers, n, value), do: Map.put(registers, n, value)
end

{options, [file]} =
  System.argv
  |> Enum.split_with(fn arg -> String.starts_with?(arg, "-") end)
samples =
  file
  |> File.stream!
  |> ChronalClassification.parse
if "-t" in options do
  samples
  |> ChronalClassification.determine_opcode_numbers
  |> ChronalClassification.execute_program(file)
else
  ChronalClassification.count_sample_behaviors(samples)
end
|> IO.puts
