defmodule Readmark.Workers.Mailer do
  use Oban.Worker, unique: [period: 60]

  alias Readmark.Mailer

  @impl Oban.Worker
  def perform(%{
        args: %{
          "recipient" => recipient,
          "subject" => subject,
          "body" => body
        }
      }) do
    from_email = Application.get_env(:readmark, :from_email, "contact@example.com")

    email =
      Swoosh.Email.new(
        to: recipient,
        from: {"Alex from readmark", from_email},
        subject: subject,
        text_body: body
      )

    with {:ok, _} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  def deliver(recipient, subject, body) do
    %{recipient: recipient, subject: subject, body: body}
    |> new()
    |> Oban.insert()
  end
end
