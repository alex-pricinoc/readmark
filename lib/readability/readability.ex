defmodule Readability do
  @moduledoc """
  Readability module for extracting articles.
  """

  @behaviour Readability.Behaviour

  @doc """
  Returns a readable text view version of an article.
  """
  @impl true
  def summarize(url) when is_binary(url) do
    bin_path()
    |> run([url])
    |> case do
      {result, 0} ->
        {:ok, Jason.decode!(result)}

      {error, _} ->
        {:error, error}
    end
  end

  defp run(command, args) when is_list(args) do
    opts = [
      stderr_to_stdout: true
    ]

    System.cmd(command, args, opts)
  end

  defp bin_path do
    (:code.priv_dir(:readmark) ++ ~c"/go/readability") |> to_string
  end
end
