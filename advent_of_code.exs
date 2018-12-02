defmodule AdventOfCode do
  def process_file(module_1, module_2, args) do
    {options, [path]} = parse_options(args)
    stream =
      path
      |> File.stream!
      |> Stream.map(fn line -> String.trim(line) end)
    if Keyword.get(options, :part_two) do
      process_stream(stream, module_2)
    else
      process_stream(stream, module_1)
    end
  end

  defp parse_options(args) do
    OptionParser.parse!(
      args,
      strict: [part_two: :boolean],
      aliases: [t: :part_two]
    )
  end

  defp process_stream(stream, module) do
    {new_stream, init} = module.init(stream)
    result = Enum.reduce_while(new_stream, init, fn item, acc ->
      case module.process(item, acc) do
        {halt_or_cont, _acc} = wrapped when halt_or_cont in ~w[halt cont]a ->
          wrapped
        unwrapped ->
          {:cont, unwrapped}
      end
    end)
    if {:answer, 1} in module.__info__(:functions) do
      module.answer(result)
    else
      result
    end
    |> IO.puts
  end
end
