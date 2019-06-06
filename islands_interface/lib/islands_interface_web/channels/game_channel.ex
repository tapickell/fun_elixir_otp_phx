defmodule IslandsInterfaceWeb.GameChannel do
  use IslandsInterfaceWeb, :channel

  alias IslandsEngine.{Game, GameSupervisor}
  alias IslandsInterfaceWeb.Presence

  @types [:atoll, :dot, :l_shape, :s_shape, :square]

  def join("game:" <> _player, %{"screen_name" => screen_name}, socket) do
    send(self(), {:after_join, screen_name})
    {:ok, socket}
  end

  def handle_info({:after_join, screen_name}, socket) do
    {:ok, _} = Presence.track(socket, screen_name, %{online_at: inspect(System.system_time(:seconds))})
    {:noreply, socket}
  end

  def handle_in("new_game", _p, socket) do
    case GameSupervisor.start_game(player(socket.topic)) do
      {:ok, pid} ->
        {:reply, :ok, socket}
      {:error, reason} ->
        {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  def handle_in("add_player", player, socket) do
    case Game.add_player(via(socket.topic), player) do
      :ok ->
        broadcast! socket, "player_added", %{message: "New player just joined: " <> player}
        {:noreply, socket}
      {:error, reason} ->
        {:reply, {:error, %{reason: inspect(reason)}}, socket}
      :error -> {:reply, :error, socket}
    end
  end

  def handle_in("position_island", %{"player" => p, "island" => i, "row" => r, "col" => c}, socket) do
    player = String.to_existing_atom(p)
    island = String.to_existing_atom(i)

    case Game.position_island(via(socket.topic), player, island, r, c) do
      :ok -> {:reply, :ok, socket}
      _ -> {:reply, :error, socket}
    end
  end

  def handle_in("set_islands", p, socket) do
    player = String.to_existing_atom(p)

    case Game.set_islands(via(socket.topic), player) do
      {:ok, board} ->
        broadcast! socket, "player_set_islands", %{player: player}
        {:reply, {:ok, %{board: inspect(board)}}, socket}
      _ -> {:reply, :error, socket}
    end
  end

  def handle_in("guess_coord", %{"player" => p, "row" => r, "col" => c}, socket) do
    player = String.to_existing_atom(p)

    case Game.guess_coord(via(socket.topic), player, r, c) do
      {:hit, island, win} ->
        result = %{hit: true, island: island, win: win}
        broadcast!(socket, "player_guessed_coord", %{player: player, row: r, col: c, result: result})
        {:noreply, socket}
      {:miss, island, win} ->
        result = %{hit: false, island: island, win: win}
        broadcast!(socket, "player_guessed_coord", %{player: player, row: r, col: c, result: result})
        {:noreply, socket}
      :error ->
        {:reply, {:error, %{player: player, reason: "Not your turn"}}, socket}
      {:error, reason} ->
        {:reply, {:error, %{player: player, reason: reason}}, socket}
    end
  end

  def handle_in("show_subscribers", _p, socket) do
    broadcast!(socket, "subscribers", Presence.list(socket))
    {:noreply, socket}
  end

  def handle_in(event, params, socket) do
    IO.inspect("Event #{inspect(event)} with params #{inspect(params)} on channel")
    {:reply, :ok, socket}
  end

  defp player("game:" <> player) do
    player
  end

  defp via(topic) do
    topic
    |> player()
    |> Game.via_tuple()
  end
end
