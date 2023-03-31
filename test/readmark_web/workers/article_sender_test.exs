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
               DateTime.new!(Kday.kday_after(Date.utc_today(), 5), ~T[12:00:00])

      prefs = %{prefs | frequency: :day}

      assert Preferences.next_delivery_date(prefs) ==
               Date.utc_today() |> Date.add(1) |> DateTime.new!(~T[12:00:00])

      prefs = %{prefs | time_zone: "Europe/Amsterdam"}

      assert Preferences.next_delivery_date(prefs) ==
               DateTime.now!("Europe/Amsterdam")
               |> DateTime.add(60 * 60 * 24)
               |> then(fn date_time ->
                 %{date_time | hour: 12, minute: 0, second: 0, microsecond: {0, 0}}
               end)
               |> DateTime.shift_zone!("Etc/UTC")
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
