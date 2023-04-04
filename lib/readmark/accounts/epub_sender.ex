defmodule Readmark.Accounts.EpubSender do
  import Swoosh.Email

  alias Readmark.Mailer

  @doc """
  Deliver epub to kindle email.
  """
  def deliver_epub(kindle_email, {epub, title}) do
    from_email = Application.get_env(:readmark, :from_email, "contact@example.com")

    email =
      new()
      |> to(kindle_email)
      |> from({"Alex from readmark", from_email})
      |> attachment(
        Swoosh.Attachment.new({:data, epub},
          filename: "#{title}.epub",
          content_type: "application/epub+zip"
        )
      )

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end
end
