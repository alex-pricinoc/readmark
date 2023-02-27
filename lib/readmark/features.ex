defmodule Readmark.Features do
  def feature_enabled?(feature_key) do
    Application.get_env(:readmark, :features)[feature_key]
  end
end
