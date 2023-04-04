defmodule Epub.Native do
  @moduledoc false

  use Rustler, otp_app: :readmark, crate: :epub

  # coveralls-ignore-start
  def add(_a, _b), do: err()

  def build(_articles, _options), do: err()

  defp err, do: :erlang.nif_error(:nif_not_loaded)
  # coveralls-ignore-stop
end
