defmodule IslandsEngine.Coordinate do
  alias __MODULE__

  @enforce_keys [:row, :col]
  @board_range 1..10

  defstruct [:row, :col]

  def new(row, col) when row in @board_range and col in @board_range do
    {:ok, %Coordinate{row: row, col: col}}
  end

  def new(_, _), do: {:error, :invalid_coordinate}

  # Using the new row and col ranges are respected but
  # if you use the %Coordinate{row: -1, 12} syntax
  # it bypasses the new guard clauses and invalid
  # coord ranges are ablt to be used. How do we enforce
  # only using the new/2 function?
end
