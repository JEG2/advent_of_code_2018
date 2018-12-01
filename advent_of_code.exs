defmodule AdventOfCode do
  def process_file(module_1, module_2, args) do
    {options, [path]} = parse_options(args)
    stream = File.stream!(path)
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
    {new_stream, acc} = module.init(stream)
    new_stream
    |> Enum.reduce_while(acc, &module.process/2)
    |> IO.puts
  end
end
