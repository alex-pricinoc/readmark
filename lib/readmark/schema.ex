defmodule Readmark.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import Ecto.Changeset

      alias Readmark.Repo

      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
