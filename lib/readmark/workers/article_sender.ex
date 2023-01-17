defmodule Readmark.Workers.ArticleSender do
  use Oban.Worker,
    max_attempts: 2,
    queue: :kindle,
    unique: [
      fields: [:args, :worker],
      keys: [:user_id],
      states: [:scheduled],
      period: :infinity
    ]

  require Logger

  alias Readmark.{Accounts, Bookmarks, Epub, Repo}
  alias Accounts.{User, EpubSender}
  alias User.KindlePreferences

  @impl Oban.Worker
  def perform(%{args: %{"user_id" => user_id} = job}) do
    Logger.debug("Sending kindle compilation: #{inspect(job)}")

    user = Accounts.get_user!(user_id)

    deliver_kindle_compilation(user)
    schedule_kindle_delivery(user)

    :ok
  end

  @impl Oban.Worker
  def backoff(_job) do
    :timer.minutes(5)
  end

  @doc """
  Schedule a new kindle delivery or updates an existing one based on user preferences.
  """
  def schedule_kindle_delivery(%User{} = user) do
    scheduled_at = KindlePreferences.next_delivery_date(user.kindle_preferences)

    %{user_id: user.id}
    |> new(
      scheduled_at: scheduled_at,
      replace: [:scheduled_at]
    )
    |> Oban.insert()
  end

  @doc """
  Delivers unread articles immediately and returns the number of sent articles.
  """
  @spec deliver_kindle_compilation(user :: User.t()) :: sent_articles_count :: integer()
  def deliver_kindle_compilation(%User{} = user) do
    bookmarks = Bookmarks.latest_unread_bookmarks(user)

    if length(bookmarks) >= user.kindle_preferences.articles do
      {epub, delete_gen_files} = bookmarks |> Enum.flat_map(& &1.articles) |> Epub.build()
      EpubSender.deliver_epub(user.kindle_email, epub)

      delete_gen_files.()
      Repo.update_all(bookmarks, set: [folder: :archive])

      Logger.info("Kindle compilation sent for user: #{user.id}.")
    else
      Logger.info("Skipping sending kindle compilation for user: #{user.id}.")
    end

    length(bookmarks)
  end

  @doc """
  Cancel an existing kindle delivery.
  """
  def cancel_kindle_delivery(%User{} = user) do
    with %Oban.Job{id: id} <- get_scheduled_delivery(user) do
      {:ok, Oban.cancel_job(id)}
    else
      _ ->
        {:ok, nil}
    end
  end

  @doc """
  Find the upcoming kindle delivery.
  """
  def get_scheduled_delivery(%User{} = user) do
    import Ecto.Query, only: [from: 2]

    Repo.one(
      from(
        j in Oban.Job,
        where:
          j.args["user_id"] == ^user.id and j.state == "scheduled" and
            j.worker == ^Oban.Worker.to_string(__MODULE__)
      )
    )
  end
end
