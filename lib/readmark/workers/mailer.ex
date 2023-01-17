defmodule Readmark.Workers.Mailer do
  use Oban.Worker, unique: [period: 60]

  alias Readmark.Mailer

  @impl Oban.Worker
  def perform(%{
        args: %{
          "to" => recipient,
          "from" => from,
          "subject" => subject,
          "text_body" => body
        }
      }) do
    from_email = Application.get_env(:readmark, :from_email, "contact@example.com")

    email =
      Swoosh.Email.new(
        to: recipient,
        from: {from, from_email},
        subject: subject,
        text_body: body
      )

    Mailer.deliver!(email)

    :ok
  end

  def deliver(recipient, subject, body) do
    email = %{
      to: recipient,
      from: "Alex from readmark",
      subject: subject,
      text_body: body
    }

    email
    |> new()
    |> Oban.insert!()

    {:ok, email}
  end
end
