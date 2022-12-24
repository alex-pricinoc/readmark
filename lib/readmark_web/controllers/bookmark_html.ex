defmodule ReadmarkWeb.BookmarkHTML do
  use ReadmarkWeb, :html

  require EEx

  bookmarks = Path.expand("templates/bookmarks.netscape.eex", __DIR__)
  EEx.function_from_file(:def, :bookmarks, bookmarks, [:assigns])
end
