defmodule Readmark.Accounts.EpubSender do
  import Swoosh.Email

  alias Readmark.Mailer

  # TODO: move to a Oban Worker

  @doc "Deliver epub to kindle."
  @spec deliver_epub(String.t(), String.t()) :: {:ok, String.t()}
  def deliver_epub(kindle_email, epub) do
    from_email = Application.get_env(:readmark, :from_email, "contact@example.com")

    email =
      new()
      |> to(kindle_email)
      |> from({"Alex from readmark", from_email})
      |> attachment(epub)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end
end
