defmodule Readmark.Repo.Migrations.AddKindleEmailToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :kindle_email, :citext
    end
  end
end
