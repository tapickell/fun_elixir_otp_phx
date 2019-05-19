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

  def guess_coord(game, player, r, c) when player in @players do
    GenServer.call(game, {:guess_coord, player, r, c})
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
         {:ok, board} <- Board.position_island(player_board(state, player), key, island) do
      new_state = update_board(state, player, board)

      {:reply, :ok, %{new_state | rules: rules}}
    else
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:set_islands, player}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player}),
         {:ok, board} <- Board.set_islands(player_board(state, player)) do

      {:reply, {:ok, board}, %{state | rules: rules}}
    else
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  def handle_call({:guess_coord, player, r, c}, _from, state) do
    opponent =  opponent(player)
    opponent_board = player_board(state, opponent)
    with {:ok, rules} <- Rules.check(state.rules, {:guess_coord, player}),
         {:ok, coord} <- Coordinate.new(r, c),
         {hit_status, forested, win_status, opponent_board} <- Board.guess(opponent_board, coord),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_status}) do

      state
      |> update_board(opponent, opponent_board)
      |> update_guesses(player, hit_status, coord)

      {:reply, {hit_status, forested, win_status}, %{state | rules: rules}}
    else
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  defp new_player(name \\ nil) do
    %{name: name, board: Board.new(), guesses: Guesses.new()}
  end

  defp opponent(:player1), do: :player2
  defp opponent(:player2), do: :player1

  defp player_board(state, player) do
    Map.get(state, player).board
  end

  defp update_board(state, player, board) do
    Map.update!(state, player, fn player ->
      %{player | board: board}
    end)
  end

  defp update_guesses(state, player, hit_status, coord) do
    update_in(state[player].guesses, fn g ->
      Guesses.add(g, hit_status, coord)
    end)
  end
end
