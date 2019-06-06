defmodule IslandsInterfaceWeb.GameChannel do
  use IslandsInterfaceWeb, :channel

  alias IslandsEngine.{Game, GameSupervisor}
  alias IslandsInterfaceWeb.Presence

  @types [:atoll, :dot, :l_shape, :s_shape, :square]

  def join("game:" <> _player, %{"screen_name" => screen_name}, socket) do
    if authorized?(socket, screen_name) do
      send(self(), {:after_join, screen_name})
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:after_join, screen_name}, socket) do
    {:ok, resp} = Presence.track(socket, screen_name, %{online_at: inspect(System.system_time(:second))})
    IO.inspect(resp, label: "After join call #{inspect(screen_name)}")
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

  defp authorized?(socket, screen_name) do
    n = number_of_players(socket) |> IO.inspect(label: "number_of_players")
    np = new_player?(socket, screen_name) |> IO.inspect(label: "new_player?")
    n < 2 && np
    |> IO.inspect(label: "authorized?")
  end

  defp number_of_players(socket) do
    socket
    |> IO.inspect(label: "num players socket")
    |> Presence.list()
    |> IO.inspect(label: "num players presence list")
    |> Map.keys()
    |> length()
  end

  defp new_player?(socket, screen_name) do
    exists = socket
    |> IO.inspect(label: "new player socket")
    |> Presence.list()
    |> IO.inspect(label: "new player presence list")
    |> Map.has_key?(screen_name)

    !exists
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
