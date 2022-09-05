# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Readmark.Repo.insert!(%Readmark.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Readmark.Bookmarks

bookmarks = [
  %{
    url: "https://kk.org/thetechnium/103-bits-of-advice-i-wish-i-had-known/",
    title: "103 Bits of Advice I Wish I Had Known",
    tags: "learning advice"
  },
  %{
    url: "https://raphaelschaad.github.io/what-should-i-start/personal.html",
    title: "Where should I start?",
    tags: "advice projects building programming"
  }
]

for bookmark <- bookmarks do
  Bookmarks.create_bookmark(bookmark)
end
