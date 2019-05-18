defmodule IslandsEngine.Board do

  alias IslandsEngine.{Coordinate, Island}

  def new(), do: %{}

  def position_island(board, key, %Island{} = island) do
    case overlaps_existing_island?(board, key, island) do
      true ->
        {:error, :overlapping_island}
      false ->
        {:ok, Map.put(board, key, island)}
    end
  end

  def guess(board, %Coordinate{} = coord) do
    board
    |> check_all_islands(coord)
    |> guess_reposne(board)
  end

  def set_islands(board) do
    if Enum.all?(Island.types, &(Map.has_key?(board, &1))) do
      {:ok, board}
    else
      {:error, :all_islands_not_positioned}
    end
  end

  defp check_all_islands(board, coord) do
    Enum.find_value(board, :miss, fn {key, island} ->
      case Island.guess(island, coord) do
        {:hit, island} -> {key, island}
        :miss -> false
      end
    end)
  end

  defp guess_reposne({key, island}, board) do
    board = %{board | key => island}
    {:hit, forest_check(board, key), win_check(board), board}
  end

  defp guess_reposne(:miss, board) do
    {:miss, :none, :no_win, board}
  end

  defp forest_check(board, key) do
    board
    |> Map.fetch!(key)
    |> Island.forested?()
    |> return_tf(key, :none)
  end

  defp win_check(board) do
    board
    |> Enum.all?(fn {_k, island} -> Island.forested?(island) end)
    |> return_tf(:win, :no_win)
  end

  defp overlaps_existing_island?(board, new_key, new_island) do
    Enum.any?(board, fn {key, island} ->
      key != new_key and Island.overlaps?(island, new_island)
    end)
  end

  defp return_tf(true, a, _), do: a
  defp return_tf(_, _, b), do: b
end
