defmodule Readmark.Dump.HTMLParser do
  @moduledoc """
  A parser for the Netscape Bookmark File Format.
  """

  def parse_document(html) do
    html
    |> Floki.parse_document!()
    |> parse_tree([])
    |> Enum.chunk_while([], &get_notes/2, &remaining/1)
    |> Enum.map(&parse_bookmark/1)
  end

  defp parse_tree([item | rest], acc) do
    {rest, acc} =
      case item do
        {"dt", [], [{"a", _, _} | _]} -> {rest, [item | acc]}
        {"dd", [], [<<_::binary>> | _]} -> {rest, [item | acc]}
        {_, _, items} -> {rest ++ items, acc}
        _ -> {rest, acc}
      end

    parse_tree(rest, acc)
  end

  defp parse_tree([], acc), do: Enum.reverse(acc)

  defp get_notes(el, []), do: {:cont, [el]}
  defp get_notes({"dt", _, _} = el, acc), do: {:cont, acc, [el]}
  defp get_notes({"dd", _, _} = el, acc), do: {:cont, [el | acc], []}

  defp remaining([]), do: {:cont, []}
  defp remaining(acc), do: {:cont, Enum.reverse(acc), []}

  defp parse_bookmark([{"dt", [], [{"a", attrs, [<<title::binary>>]} | _]}]) do
    to_link(title, "", attrs)
  end

  defp parse_bookmark([{"dd", [], []}, {"dt", [], [{"a", attrs, [<<title::binary>>]} | _]}]) do
    to_link(title, "", attrs)
  end

  defp parse_bookmark([
         {"dd", [], [<<notes::binary>> | _]},
         {"dt", [], [{"a", attrs, [<<title::binary>>]} | _]}
       ]) do
    to_link(title, notes, attrs)
  end

  defp parse_bookmark(unmatched) do
    {:error, to_html(unmatched)}
  end

  @error_node "__ERROR_TAG__"

  defp to_html(tokens) do
    {@error_node, [], tokens}
    |> Floki.raw_html()
    |> String.replace(~r/^<#{@error_node}>/, "")
    |> String.replace(~r/<\/#{@error_node}>$/, "")
  end

  defp to_link(title, notes, attrs) when is_list(attrs) do
    to_link(title, notes, Enum.into(attrs, %{}))
  end

  defp to_link(title, notes, %{"href" => url} = attrs) do
    {:ok,
     %{
       url: url,
       title: title,
       notes: notes,
       tags: Map.get(attrs, "tags", []),
       is_private: is_private(attrs),
       inserted_at: inserted_at(attrs)
     }}
  end

  defp inserted_at(%{"add_date" => timestamp}) do
    timestamp
    |> String.to_integer()
    |> DateTime.from_unix!()
  end

  defp inserted_at(_) do
    DateTime.utc_now()
  end

  defp is_private(%{"private" => value}) when value not in ~w(1 true yes), do: false
  defp is_private(_), do: true
end
