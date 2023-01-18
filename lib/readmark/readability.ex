defmodule Readmark.Readability do
  @doc """
  Summarizes the given url.
  """
  @spec summarize(String.t()) :: {:ok, Summary.t()} | {:error, String.t()}
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
      stderr_to_stdout: true,
      parallelism: true
    ]

    System.cmd(command, args, opts)
  end

  defp bin_path do
    (:code.priv_dir(:readmark) ++ '/go/readability') |> to_string
  end
end
