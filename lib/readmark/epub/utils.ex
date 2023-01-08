defmodule Readmark.Epub.Utils do
  @moduledoc false

  alias Vix.Vips.Image, as: Vimage

  @doc "Generates a random alphanumeric id."
  def gen_reference() do
    min = String.to_integer("100000", 36)
    max = String.to_integer("ZZZZZZ", 36)

    max
    |> Kernel.-(min)
    |> :rand.uniform()
    |> Kernel.+(min)
    |> Integer.to_string(36)
  end

  @width 640
  @height 960

  @doc "Generates EPUB cover from text."
  @spec build_cover(text :: String.t(), path :: String.t()) :: Vimage.t()
  def build_cover(text, path) do
    image = Image.new!(@width, @height)
    title = title()
    text = text(image, text)

    image
    |> Image.compose!(title, title_location(image, title))
    |> Image.compose!(text, text_location(image, text))
    |> Image.write!(path)
  end

  defp title do
    Image.Text.simple_text!("readmark",
      font_size: 100,
      font_weight: :bold,
      font: "Inria Serif",
      align: :center
    )
  end

  defp text(image, text) do
    Image.Text.simple_text!(text,
      autofit: true,
      width: text_box_width(image),
      font: "sans",
      font_size: 100,
      height: 100,
      align: :center
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
