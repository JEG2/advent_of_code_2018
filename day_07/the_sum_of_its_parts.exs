defmodule TheSumOfItsParts do
  defstruct dependencies: Map.new

  def init(stream) do
    {stream, %__MODULE__{ }}
  end

  def process(step, state) do
    steps = Regex.named_captures(
      ~r{Step (?<enabler>\w) must be finished before step (?<dependency>\w)},
      step
    )
    %__MODULE__{
      state |
      dependencies: Map.update(
        state.dependencies,
        Map.fetch!(steps, "enabler"),
        [Map.fetch!(steps, "dependency")],
        &[Map.fetch!(steps, "dependency") | &1]
      )
    }
  end

  def answer(state) do
    state.dependencies
    |> Map.keys
    |> Kernel.++(state.dependencies |> Map.values |> List.flatten)
    |> Enum.uniq
    |> Enum.reduce(state.dependencies, fn step, full ->
      Map.put_new(full, step, [ ])
    end)
    |> build("")
  end

  defp build(dependencies, order) when map_size(dependencies) == 0, do: order
  defp build(dependencies, order) do
    waiting =
      dependencies
      |> Map.values
      |> List.flatten
      |> Enum.uniq
    available = Map.keys(dependencies) -- waiting
    first = available |> Enum.sort |> hd
    build(Map.delete(dependencies, first), order <> first)
  end
end

defmodule TheSumOfItsPartsPartTwo do
  defstruct second: 0,
            workers: Enum.into(0..4, Map.new, &{&1, nil}),
            done: "",
            available: [ ],
            dependencies: nil

  defdelegate init(stream), to: TheSumOfItsParts
  defdelegate process(step, state), to: TheSumOfItsParts

  def answer(state) do
    dependencies =
      state.dependencies
      |> Map.keys
      |> Kernel.++(state.dependencies |> Map.values |> List.flatten)
      |> Enum.uniq
      |> Enum.reduce(state.dependencies, fn step, full ->
        Map.put_new(full, step, [ ])
      end)
    tick(%__MODULE__{dependencies: dependencies})
    |> Map.fetch!(:second)
  end

  defp tick(%__MODULE__{dependencies: dependencies} = state)
  when map_size(dependencies) == 0,
    do: state
  defp tick(state) do
    state
    |> add_work
    |> assign_work
    |> work
    |> finish_work
    |> tick
  end

  defp add_work(state) do
    waiting =
      state.dependencies
      |> Map.values
      |> List.flatten
      |> Enum.uniq
    working =
      state.workers
      |> Enum.reject(fn {_id, work} -> is_nil(work) end)
      |> Enum.map(fn {_id, {work, _time}} -> work end)
    available =
      state.dependencies
      |> Map.keys
      |> Kernel.--(waiting)
      |> Kernel.--(working)
      |> Enum.sort
    %__MODULE__{state | available: available}
  end

  defp assign_work(state) do
    available_workers =
      state.workers
      |> Enum.filter(fn {_id, work} -> is_nil(work) end)
      |> Enum.map(fn {id, _work} -> id end)
      |> Enum.sort
    new_workers =
      state.available
      |> Enum.zip(available_workers)
      |> Enum.reduce(state.workers, fn {work, id}, workers ->
        Map.put(workers, id, {work, seconds(work)})
      end)
    new_available =
      state.available
      |> Enum.drop(length(available_workers))
    %__MODULE__{state | workers: new_workers, available: new_available}
  end

  defp seconds(<<offset::utf8>>) do
    offset - ?A + 61
  end

  defp work(state) do
    fastest_work =
      state.workers
      |> Enum.reject(fn {_id, work} -> is_nil(work) end)
      |> Enum.map(fn {_id, {_work, time}} -> time end)
      |> Enum.min
    new_workers =
      state.workers
      |> Enum.into(Map.new, fn
        {_id, nil} = idle ->
          idle
        {id, {work, time}} ->
          {id, {work, time - fastest_work}}
      end)
    %__MODULE__{
      state |
      second: state.second + fastest_work,
      workers: new_workers
    }
  end

  defp finish_work(state) do
    finished =
      state.workers
      |> Enum.filter(&match?({_id, {_work, 0}}, &1))
      |> Enum.map(fn {_id, {work, 0}} -> work end)
      |> Enum.sort
    new_workers =
      state.workers
      |> Enum.into(Map.new, fn
        {id, {_work, 0}} ->
          {id, nil}
        worker ->
          worker
      end)
    %__MODULE__{
      state |
      workers: new_workers,
      done: state.done <> Enum.join(finished),
      dependencies: Map.drop(state.dependencies, finished)
    }
  end
end

Code.require_file "../advent_of_code.exs", __DIR__
AdventOfCode.process_file(
  TheSumOfItsParts,
  TheSumOfItsPartsPartTwo,
  System.argv
)
