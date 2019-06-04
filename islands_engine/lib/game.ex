defmodule IslandsEngine.Game do
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient

  alias IslandsEngine.{Board, Coordinate, Guesses, Island, Player, Rules}

  @players Player.valid_players()
  @timeout 15000 * 60

  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def init(name) do
    {:ok, %{player1: Player.new(name), player2: Player.new(), rules: %Rules{}}, @timeout}
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
      |> update_rules(rules)

      reply(:ok, new_state)
    else
      :error -> reply(:error, state)
    end
  end

  def handle_call({:position_island, player, key, r, c}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, {:position_islands, player}),
         {:ok, coord} <- Coordinate.new(r, c),
         {:ok, island} <- Island.new(key, coord),
         {:ok, board} <- Board.position_island(player_board(state, player), key, island) do
      new_state = state
      |> update_board(player, board)
      |> update_rules(rules)

      reply(:ok, new_state)
    else
      {:error, error} -> reply({:error, error}, state)
    end
  end

  def handle_call({:set_islands, player}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player}),
         {:ok, board} <- Board.set_islands(player_board(state, player)) do

      reply({:ok, board}, update_rules(state, rules))
    else
      {:error, error} -> reply({:error, error}, state)
    end
  end

  def handle_call({:guess_coord, player, r, c}, _from, state) do
    opponent =  Player.opponent(player)
    opponent_board = player_board(state, opponent)
    with {:ok, rules} <- Rules.check(state.rules, {:guess_coord, player}),
         {:ok, coord} <- Coordinate.new(r, c),
         {hit_status, forested, win_status, opponent_board} <- Board.guess(opponent_board, coord),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_status}) do

      state
      |> update_board(opponent, opponent_board)
      |> update_guesses(player, hit_status, coord)
      |> update_rules(rules)

      reply({hit_status, forested, win_status}, state)
    else
      {:error, error} -> reply({:error, error}, state)
    end
  end

  def handle_info(:timeout, state) do
    {:stop, {:shutdown, :timeout}, state}
  end

  def via_tuple(name) do
    {:via, Registry, {Registry.Game, name}}
  end

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

  defp update_rules(state, rules) do
    %{state | rules: rules}
  end

  defp reply(reply, state) do
    {:reply, reply, state, @timeout}
  end
end
