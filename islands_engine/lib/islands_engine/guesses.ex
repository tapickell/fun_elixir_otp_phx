defmodule IslandsEngine.Guesses do
  alias __MODULE__

  @enforce_keys [:hits, :misses]

  defstruct [:hits, :misses]

  def new(), do: %Guesses{hits: MapSet.new(), misses: MapSet.new()}

  # using MapSet gives us uniquness in each catagory
  # but what makes sure we don't get dupicates in both?
  # You can add a coord to hits and then add the same coord
  # to misses with no issues
end
