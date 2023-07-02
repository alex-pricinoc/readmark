defmodule Readmark.Accounts.EpubSender do
  import Swoosh.Email

  alias Readmark.Mailer

  def deliver_epub(_epub, _email = nil) do
    {:error, "kindle email was not specified."}
  end

  def deliver_epub({epub, title}, kindle_email) do
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
