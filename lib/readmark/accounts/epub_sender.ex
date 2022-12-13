defmodule Readmark.Accounts.EpubSender do
  import Swoosh.Email

  alias Readmark.Mailer

  # TODO: move to a Oban Worker

  @from_email Application.compile_env!(:readmark, :from_email)

  @doc "Deliver epub to kindle."
  @spec deliver_epub(String.t(), String.t()) :: {:ok, String.t()}
  def deliver_epub(kindle_email, epub) do
    email =
      new()
      |> to(kindle_email)
      |> from(@from_email)
      |> attachment(epub)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end
end
