defmodule Readmark.Readability do
  defmodule Summary do
    defstruct [:url, :title, :excerpt, :content, :text_content, :length]
  end

  @type result :: {:ok, Summary.t()} | {:error, String.t()} | {:killed, String.t()}

  @doc """
  Summarizes the given url.
  """
  @spec summarize(url :: String.t()) :: result()
  def summarize(url) do
    start_port(url)
    |> receive_result
    |> output_to_binary
    |> decode
  end

  defp receive_result(port, result \\ []) do
    receive do
      {^port, {:data, data}} ->
        receive_result(port, [result | data])

      {^port, {:exit_status, 0}} ->
        {:ok, result}

      {^port, {:exit_status, _}} ->
        {:error, result}
    after
      5000 ->
        Port.close(port)
        {:killed, result}
    end
  end

  defp output_to_binary({reason, result}) do
    {reason, to_binary(result)}
  end

  defp to_binary(iodata) when is_list(iodata) do
    IO.iodata_to_binary(iodata)
  end

  defp to_binary(output) do
    output
  end

  defp decode({:ok, output}) do
    {:ok, Jason.decode!(output, keys: :atoms) |> then(&struct!(Summary, &1))}
  end

  defp decode(result) do
    result
  end

  defp start_port(arg) when is_binary(arg) do
    start_port([arg])
  end

  defp start_port(args) when is_list(args) do
    path = :code.priv_dir(:readmark) ++ '/go/readability'
    Port.open({:spawn_executable, path}, [:binary, :exit_status, args: args])
  end
end
