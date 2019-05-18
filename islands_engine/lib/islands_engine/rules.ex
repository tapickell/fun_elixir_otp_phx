defmodule IslandsEngine.Rules do
  alias __MODULE__

  defstruct state: :initialized,
    player1: :islands_not_set,
    player2: :islands_not_set

  def new(), do: %Rules{}

  def check(%Rules{state: :initialized} = rules, :add_player) do
    {:ok, %Rules{rules | state: :players_set}}
  end

  def check(%Rules{state: :players_set, player1: :islands_not_set} = rules,
    {:position_islands, :player1}) do
    {:ok, rules}
  end

  def check(%Rules{state: :players_set, player2: :islands_not_set} = rules,
    {:position_islands, :player2}) do
    {:ok, rules}
  end

  def check(%Rules{state: :players_set} = rules, {:set_islands, player}) do
    rules = Map.put(rules, player, :islands_set)
    case both_players_islands_set?(rules) do
      true -> {:ok, %Rules{rules | state: :player1_turn}}
      false -> {:ok, rules}
    end
  end

  def check(%Rules{state: :player1_turn} = rules, {:guess_coord, :player1}) do
    {:ok, %Rules{rules | state: :player2_turn}}
  end

  def check(%Rules{state: :player2_turn} = rules, {:guess_coord, :player2}) do
    {:ok, %Rules{rules | state: :player1_turn}}
  end

  def check(%Rules{state: :player1_turn} = rules, {:win_check, :win}) do
    {:ok, %Rules{rules | state: :game_over}}
  end

  def check(%Rules{state: :player1_turn} = rules, {:win_check, :no_win}) do
    {:ok, rules}
  end

  def check(%Rules{state: :player2_turn} = rules, {:win_check, :win}) do
    {:ok, %Rules{rules | state: :game_over}}
  end

  def check(%Rules{state: :player2_turn} = rules, {:win_check, :no_win}) do
    {:ok, rules}
  end

  def check(_state, _action), do: {:error, :rules_not_allowed}

  defp both_players_islands_set?(%Rules{player1: :islands_set, player2: :islands_set}), do: true
  defp both_players_islands_set?(_rules), do: false
end
