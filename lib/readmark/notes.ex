defmodule Readmark.Notes do
  for app <- [:earmark] do
    Application.ensure_all_started(app)
  end

  alias Readmark.Notes.Note

  notes_paths = "notes/**/*.md" |> Path.wildcard() |> Enum.sort()

  notes =
    for note_path <- notes_paths do
      @external_resource Path.relative_to_cwd(note_path)
      Note.parse!(note_path)
    end

  @notes Enum.sort_by(notes, & &1.date, {:desc, Date})

  def list_notes do
    @notes
  end

  defmodule NotFoundError do
    defexception [:message, plug_status: 404]
  end

  @tags notes |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  def list_tags do
    @tags
  end

  def get_notes_by_tag!(tag) do
    case Enum.filter(list_notes(), &(tag in &1.tags)) do
      [] -> raise NotFoundError, "notes with tag=#{tag} not found"
      notes -> notes
    end
  end
end
