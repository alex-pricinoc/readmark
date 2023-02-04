defmodule Readmark.Accounts.EpubSender do
  import Swoosh.Email

  alias Readmark.Mailer

  @doc """
  Deliver epub to kindle email.
  """
  @spec deliver_epub(kindle_email :: String.t(), book_path :: String.t()) :: {:ok, term()}
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
