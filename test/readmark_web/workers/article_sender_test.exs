defmodule Readmark.Workers.ArticleSenderTest do
  use Readmark.DataCase

  import Swoosh.TestAssertions
  import Readmark.{AccountsFixtures, BookmarksFixtures}

  alias Readmark.Workers.ArticleSender
  alias Readmark.Accounts.User.KindlePreferences, as: Preferences

  describe "kindle deliveries" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "delivery datetimes are correct" do
      prefs = %Preferences{frequency: :week, time: ~T[12:00:00], time_zone: "Etc/UTC"}

      assert Preferences.next_delivery_date(prefs) ==
               Timex.now()
               |> then(&Timex.set(&1, date: Kday.kday_after(&1, 5), time: ~T[12:00:00]))

      prefs = %{prefs | frequency: :day}

      assert Preferences.next_delivery_date(prefs) ==
               Timex.now() |> Timex.set(time: ~T[12:00:00]) |> Timex.shift(days: 1)

      prefs = %{prefs | time_zone: "Europe/Amsterdam"}

      assert Preferences.next_delivery_date(prefs) ==
               Timex.now("Europe/Amsterdam")
               |> Timex.shift(days: 1)
               |> Timex.set(time: ~T[12:00:00])
               |> Timex.Timezone.convert("Etc/UTC")
    end
  end

  describe "deliver_kindle_compilation/2" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "email is sent", %{user: user} do
      user = %{user | kindle_email: "some.email@free.kindle.com"}

      article = article_fixture()

      assert {:ok, 1} = ArticleSender.deliver_kindle_compilation(user, [article])

      assert_email_sent(fn email ->
        assert %{attachments: [%{content_type: "application/epub+zip"}]} = email
      end)
    end
  end
end
