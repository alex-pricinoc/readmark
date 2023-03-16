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

  alias Readmark.{Accounts, Bookmarks, Repo}
  alias Accounts.{User, EpubSender}
  alias User.KindlePreferences

  @impl Oban.Worker
  def perform(%{args: %{"user_id" => user_id} = job}) do
    Logger.debug("Performing scheduled kindle delivery: #{inspect(job)}")

    user = Accounts.get_user!(user_id)
    bookmarks = Bookmarks.latest_unread_bookmarks(user)
    articles = Enum.flat_map(bookmarks, & &1.articles)

    if should_deliver?(user, articles) do
      case deliver_kindle_compilation(user, articles) do
        {:ok, sent} ->
          _ = Enum.map(bookmarks, &Bookmarks.update_bookmark(&1, %{folder: :archive}))
          Logger.info("Kindle compilation sent for user: #{user.id}. #{sent} articles.")

        {:error, error} = err ->
          Logger.error("An error has occured while delivering articles: #{error}")
          err
      end
    else
      Logger.info("Skipping sending kindle compilation for user: #{user.id}.")
    end

    schedule_kindle_delivery(user)

    :ok
  end

  @impl Oban.Worker
  def backoff(_job), do: :timer.minutes(5)

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(5)

  @doc """
  Schedule a new kindle delivery or updates an existing one based on user preferences.
  """
  def schedule_kindle_delivery(%User{} = user) when user.kindle_preferences.is_scheduled? do
    scheduled_at = KindlePreferences.next_delivery_date(user.kindle_preferences)

    %{user_id: user.id}
    |> new(
      scheduled_at: scheduled_at,
      replace: [:scheduled_at]
    )
    |> Oban.insert()
  end

  @doc """
  Delivers articles to user kindle email immediately. Returns the number of sent articles.
  """
  def deliver_kindle_compilation(%User{} = user, articles)
      when length(articles) > 0 and user.kindle_email != nil do
    with {:ok, {epub, delete_gen_files}} <- Epub.build(articles),
         {:ok, _email} = EpubSender.deliver_epub(user.kindle_email, epub) do
      delete_gen_files.()

      {:ok, length(articles)}
    else
      error -> error
    end
  end

  @doc """
  Cancel an existing kindle delivery.
  """
  def cancel_kindle_delivery(%User{} = user) when not user.kindle_preferences.is_scheduled? do
    with %Oban.Job{id: id} <- get_scheduled_delivery(user) do
      {:ok, Oban.cancel_job(id)}
    else
      _ -> {:ok, nil}
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

  defp should_deliver?(user, articles) do
    length(articles) >= user.kindle_preferences.articles and user.kindle_email != nil
  end
end
