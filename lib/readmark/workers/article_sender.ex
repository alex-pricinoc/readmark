defmodule Readmark.Workers.ArticleSender do
  use Oban.Worker,
    max_attempts: 2,
    queue: :kindle,
    priority: 3,
    unique: [
      fields: [:args, :worker],
      keys: [:user_id],
      states: [:scheduled],
      period: :infinity
    ]

  require Logger

  alias Readmark.{Accounts, Bookmarks, Repo}
  alias Accounts.{User, EpubSender}

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(5)

  @impl Oban.Worker
  def backoff(_job), do: :timer.minutes(10)

  @impl Oban.Worker
  def perform(%{args: %{"user_id" => user_id} = job}) do
    Logger.info("Performing scheduled kindle delivery: #{inspect(job)}")

    user = Accounts.get_user!(user_id)

    case deliver_kindle_compilation(user, user.kindle_preferences.articles) do
      {:ok, 0} = res ->
        schedule_kindle_delivery(user)
        Logger.info("Skipping sending kindle compilation for user #{user.id}.")
        res

      {:ok, sent} = res ->
        schedule_kindle_delivery(user)
        Logger.info("Kindle compilation sent for user #{user.id}, #{sent} articles.")
        res

      {:error, error} = err ->
        Logger.error("An error has occured while delivering articles: #{error}")
        err
    end
  end

  @doc """
  Delivers latest articles to user kindle email.
  """
  def deliver_kindle_compilation(user, articles \\ 1)

  def deliver_kindle_compilation(%User{} = user, articles)
      when is_integer(articles) do
    bookmarks = Bookmarks.latest_unread_bookmarks(user)
    unread_articles = Enum.flat_map(bookmarks, & &1.articles)

    if length(unread_articles) >= articles do
      case deliver_kindle_compilation(user, unread_articles) do
        {:ok, sent} = res when sent > 0 ->
          Enum.map(bookmarks, &Bookmarks.update_bookmark(&1, %{folder: :archive}))
          res

        err ->
          err
      end
    else
      {:ok, 0}
    end
  end

  def deliver_kindle_compilation(%User{} = user, articles) when is_list(articles) do
    with {:ok, epub} <- Epub.build(articles, user.kindle_preferences),
         {:ok, _email} <- EpubSender.deliver_epub(epub, user.kindle_email) do
      {:ok, length(articles)}
    else
      err -> err
    end
  end

  @doc """
  Schedule a new kindle delivery or updates an existing one based on user preferences.
  """
  def schedule_kindle_delivery(%User{} = user) when user.kindle_preferences.is_scheduled? do
    scheduled_at = User.KindlePreferences.next_delivery_date(user.kindle_preferences)

    %{user_id: user.id}
    |> new(
      scheduled_at: scheduled_at,
      replace: [:scheduled_at]
    )
    |> Oban.insert()
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
end
