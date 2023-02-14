defmodule Readability.Behaviour do
  @callback summarize(url :: String.t()) :: {:ok, map()} | {:error, String.t()}
end
