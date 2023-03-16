defmodule Epub.Cover do
  @moduledoc false

  @width 640
  @height 960

  @doc "Generates EPUB cover from text."
  def build_cover(text, dest) do
    image = Image.new!(@width, @height)
    text = text!(image, text)
    title = title!(image)

    image
    |> Image.compose!(title, title_location(image, title))
    |> Image.compose!(text, text_location(image, text))
    |> Image.write!(dest)
  end

  defp title!(image) do
    Image.Text.simple_text!("readmark",
      autofit: true,
      font_size: 0,
      font_weight: :bold,
      font: "Inria Serif",
      height: 50,
      width: text_box_width(image)
    )
  end

  defp text!(image, text) do
    Image.Text.simple_text!(text,
      autofit: true,
      font_size: 0,
      font: "sans-serif",
      align: :center,
      height: 100,
      width: text_box_width(image)
    )
  end

  @title_distance_from_top 0.3
  @text_distance_from_bottom 0.15

  defp title_location(image, text) do
    x = ((Image.width(image) - Image.width(text)) / 2) |> round()
    y = (Image.height(image) * @title_distance_from_top) |> round()
    [x: x, y: y]
  end

  defp text_location(image, text) do
    x = ((Image.width(image) - Image.width(text)) / 2) |> round()

    y =
      (Image.height(image) - Image.height(text) -
         Image.height(image) * @text_distance_from_bottom)
      |> round()

    [x: x, y: y]
  end

  defp text_box_width(image, margin \\ 32) do
    Image.width(image) - 2 * margin
  end
end
