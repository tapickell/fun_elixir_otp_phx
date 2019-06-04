defmodule IslandsEngine.Player do
  alias IslandsEngine.{Board, Guesses}

  @valid_players [:player1, :player2]

  defstruct [:name, :board, :guesses]

  def new(name \\ nil) do
    %{name: name, board: Board.new(), guesses: Guesses.new()}
  end

  def valid_players() do
    @valid_players
  end

  def opponent(:player1), do: :player2
  def opponent(:player2), do: :player1

end
