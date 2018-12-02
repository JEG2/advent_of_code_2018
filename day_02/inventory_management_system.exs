defmodule InventoryManagementSystem do
  defstruct twos: 0, threes: 0

  def init(stream) do
    {stream, %__MODULE__{ }}
  end

  def process(id, counts) do
    checksum = count(id)
    two? = Enum.any?(checksum, fn {_letter, count} -> count == 2 end)
    three? = Enum.any?(checksum, fn {_letter, count} -> count == 3 end)
    %__MODULE__{
      counts |
      twos: counts.twos + (if two?, do: 1, else: 0),
      threes: counts.threes + (if three?, do: 1, else: 0)
    }
  end

  def answer(counts) do
    counts.twos * counts.threes
  end

  defp count(id) do
    letters = String.graphemes(id)
    letters
    |> Enum.uniq
    |> Enum.into(Map.new, fn letter ->
      {letter, Enum.count(letters, fn other -> letter == other end)}
    end)
  end
end

defmodule InventoryManagementSystemPartTwo do
  def init(stream) do
    {stream, [ ]}
  end

  def process(id, ids_so_far) do
    case Enum.find(ids_so_far, fn other -> off_by_one?(id, other) end) do
      match when not is_nil(match) ->
        {
          :halt,
          id
          |> String.graphemes
          |> Enum.zip(String.graphemes(match))
          |> Enum.reject(fn {id_char, match_char} -> id_char != match_char end)
          |> Enum.map(fn {char, _dupe} -> char end)
          |> Enum.join
        }
      nil ->
        {:cont, [id | ids_so_far]}
    end
  end

  defp off_by_one?(str_1, str_2) do
    case String.myers_difference(str_1, str_2) do
      [del: <<_del::utf8>>, ins: <<_ins::utf8>>, eq: suffix]
      when is_binary(suffix) ->
        true
      [eq: prefix, del: <<_del::utf8>>, ins: <<_ins::utf8>>, eq: suffix]
      when is_binary(prefix) and is_binary(suffix) ->
        true
      [eq: prefix, del: <<_del::utf8>>, ins: <<_ins::utf8>>]
      when is_binary(prefix) ->
        true
      _edit_script ->
        false
    end
  end
end

Code.require_file "../advent_of_code.exs", __DIR__
AdventOfCode.process_file(
  InventoryManagementSystem,
  InventoryManagementSystemPartTwo,
  System.argv
)
