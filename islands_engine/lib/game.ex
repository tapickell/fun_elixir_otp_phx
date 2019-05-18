defmodule IslandsEngine.Game do
  use GenServer

  alias IslandsEngine.{Board, Coordinate, Guesses, Island, Rules}

  @players [:player1, :player2]

  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, [])
  end

  def init(name) do
    {:ok, %{player1: new_player(name), player2: new_player(), rules: %Rules{}}}
  end

  def add_player(game, name) when is_binary(name) do
    GenServer.call(game, {:add_player, name})
  end

  def position_island(game, player, key, r, c) when player in @players do
    GenServer.call(game, {:position_island, player, key, r, c})
  end

  def set_islands(game, player) when player in @players do
    GenServer.call(game, {:set_islands, player})
  end

  def handle_call({:add_player, name}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :add_player) do
      new_state = put_in(state.player2.name, name)

      {:reply, :ok, %{new_state | rules: rules}}
    else
      :error -> {:reply, :error, state}
    end
  end

  def handle_call({:position_island, player, key, r, c}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, {:position_islands, player}),
         {:ok, coord} <- Coordinate.new(r, c),
         {:ok, island} <- Island.new(key, coord),
         {:ok, board} <- Board.position_island(Map.get(state, player).board, key, island) do
      new_state = Map.update!(state, player, fn player ->
        %{player | board: board}
      end)

      {:reply, :ok, %{new_state | rules: rules}}
    else
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:set_islands, player}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player}),
         {:ok, board} <- Board.set_islands(Map.get(state, player).board) do

      {:reply, {:ok, board}, %{state | rules: rules}}
    else
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  defp new_player(name \\ nil) do
    %{name: name, board: Board.new(), guesses: Guesses.new()}
  end
end
