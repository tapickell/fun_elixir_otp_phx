defmodule IslandsEngine.Island do
  alias __MODULE__
  alias IslandsEngine.{Coordinate, Guesses}

  @enforce_keys [:coords, :hit_coords]

  defstruct [:coords, :hit_coords]

  def new(type, %Coordinate{} = root) do
    with [_ | _] = offsets = offsets(type),
         %MapSet{} = coords = add_coordinates(offsets, root) do
      {:ok, %Island{coords: coords, hit_coords: MapSet.new()}}
    end
  end

  defp add_coordinates(offsets, root) do
    Enum.reduce_while(offsets, MapSet.new(), fn off, acc ->
      add_coordinate(acc, root, off)
    end)
  end

  defp add_coordinate(coords, %Coordinate{row: row, col: col}, {ro, co}) do
    case Coordinate.new(row + ro, col + co) do
      {:ok, coord} ->
        {:cont, MapSet.put(coords, coord)}

      {:error, :invalid_coordinate} ->
        {:halt, {:error, :invalid_coordinate}}
    end
  end

  defp offsets(:dot), do: dot()
  defp offsets(:square), do: square(dot())
  defp offsets(:atoll), do: atoll(dot())
  defp offsets(:l_shape), do: l_shape(dot())
  defp offsets(:s_shape), do: s_shape(dot())
  defp offsets(_), do: {:error, :invalid_island_type}

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
  defp oxy({x, y}, n), do: {x + n, x + n}
  defp oxy({x, y}, n, m), do: {x + n, x + m}
end
