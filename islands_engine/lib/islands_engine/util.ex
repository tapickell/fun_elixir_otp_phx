defmodule IslandsEngine.Util do

  def succeeded({:error, _} = error), do: error
  def succeeded(result), do: {:ok, result}
end
