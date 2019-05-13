defmodule IslandsEngine.Guesses do
  alias __MODULE__
  alias IslandsEngine.Coordinate

  @enforce_keys [:hits, :misses]

  defstruct [:hits, :misses]

  def new(), do: %Guesses{hits: MapSet.new(), misses: MapSet.new()}

  def add(%Guesses{} = guesses, :hit, %Coordinate{} = coord) do
    update_in(guesses.hits, &MapSet.put(&1, coord))
  end

  def add(%Guesses{} = guesses, :miss, %Coordinate{} = coord) do
    update_in(guesses.misses, &MapSet.put(&1, coord))
  end



  # using MapSet gives us uniquness in each catagory
  # but what makes sure we don't get dupicates in both?
  # You can add a coord to hits and then add the same coord
  # to misses with no issues
end
