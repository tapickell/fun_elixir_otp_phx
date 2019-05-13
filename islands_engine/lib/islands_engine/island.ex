defmodule IslandsEngine.Island do
  alias __MODULE__
  alias IslandsEngine.{Coordinate, Guesses, Util}

  @enforce_keys [:coords, :hit_coords]

  @types [:atoll, :dot, :l_shape, :s_shape, :square]

  defstruct [:coords, :hit_coords]

  def new(type, %Coordinate{} = root) do
    with {:ok, offsets} <- offsets_for(type),
         {:ok, coords} <- add_coordinates(offsets, root) do
      {:ok, %Island{coords: coords, hit_coords: MapSet.new()}}
    else
      {:error, error} -> {:error, error}
    end
  end

  def types(), do: @types

  def guess(island, coord) do
    case MapSet.member?(island.coords, coord) do
      true ->
        hit_coords = MapSet.put(island.hit_coords, coord)
        {:hit, %{island | hit_coords: hit_coords}}
      false ->
        :miss
    end
  end

  def forested?(island) do
    MapSet.equal?(island.coords, island.hit_coords)
  end

  def overlaps?(existing, new) do
    not MapSet.disjoint?(existing.coords, new.coords)
  end

  defp add_coordinates(offsets, root) do
    Enum.reduce_while(offsets, MapSet.new(), fn off, acc ->
      add_coordinate(acc, root, off)
    end)
    |> Util.succeeded()
  end

  defp add_coordinate(coords, %Coordinate{row: row, col: col}, {ro, co}) do
    case Coordinate.new(row + ro, col + co) do
      {:ok, coord} ->
        {:cont, MapSet.put(coords, coord)}

      {:error, :invalid_coordinate} ->
        {:halt, {:error, :invalid_coordinate}}
    end
  end

  defp offsets_for(type) when type in @types do
    offsets(type) |> Util.succeeded()
  end
  defp offsets_for(_), do: {:error, :invalid_island_type}

  defp offsets(:dot), do: [dot()]
  defp offsets(:square), do: square(dot())
  defp offsets(:atoll), do: atoll(dot())
  defp offsets(:l_shape), do: l_shape(dot())
  defp offsets(:s_shape), do: s_shape(dot())

  defp dot(), do: {0, 0}

  defp square(off) do
    [off, oy(off, 1), ox(off, 1), oxy(off, 1)]
  end

  defp atoll(off) do
    [off, oy(off, 1), oxy(off, 1), ox(off, 2), oxy(off, 2, 1)]
  end

  defp l_shape(off) do
    [off, ox(off, 1), ox(off, 2), oxy(off, 2, 1)]
  end

  defp s_shape(off) do
    [oy(off, 1), oy(off, 2), ox(off, 1), oxy(off, 1)]
  end

  defp ox({x, y}, n), do: {x + n, y}
  defp oy({x, y}, n), do: {x, y + n}
  defp oxy({x, _y}, n), do: {x + n, x + n}
  defp oxy({x, y}, n, m), do: {x + n, y + m}
end
