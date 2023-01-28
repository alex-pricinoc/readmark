defmodule Readability.Behaviour do
  @callback summarize(String.t()) :: {:ok, map()} | {:error, String.t()}
end
