defmodule Readmark.Accounts.User.KindlePreferences do
  use Readmark.Schema

  alias __MODULE__, as: Preferences

  defmodule ParsedTime do
    use Ecto.Type

    @impl true
    def type, do: :time

    @impl true
    def cast(str_time) when is_binary(str_time) do
      case Time.from_iso8601(str_time) do
        {:ok, time} -> {:ok, time}
        _ -> :error
      end
    end

    @impl true
    def cast(%Time{} = time), do: {:ok, time}
    def cast(_), do: :error

    @impl true
    def load(%Time{} = time), do: {:ok, time}

    @impl true
    def dump(%Time{} = time), do: {:ok, time}
    def dump(_), do: :error
  end

  @primary_key false
  embedded_schema do
    field :is_scheduled?, :boolean, default: false
    field :frequency, Ecto.Enum, values: [day: 1, week: 7], default: :week
    field :articles, :integer, default: 10
    field :time, ParsedTime, default: ~T[00:00:00]
    field :time_zone, :string, default: "Etc/UTC"
  end

  @params ~w(is_scheduled? frequency articles time time_zone)a

  def changeset(preferences, attrs) do
    cast(preferences, attrs, @params)
  end

  def next_delivery_date(%Preferences{} = preferences) do
    now = Timex.now(preferences.time_zone)

    now
    |> set(preferences)
    |> Timex.Timezone.convert("Etc/UTC")
  end

  defp set(date, %{frequency: :day, time: time}) do
    date
    |> Timex.set(time: time)
    |> Timex.shift(days: 1)
  end

  defp set(date, %{frequency: :week, time: time}) do
    # weekly deliveries are always sent on friday
    friday = Kday.kday_after(date, 5)
    Timex.set(date, date: friday, time: time)
  end
end
