defmodule HtmlSanitizeEx2 do
  alias HtmlSanitizeEx.Scrubber

  def basic_html_reduced(html) do
    html |> Scrubber.scrub(Scrubber.BasicHTMLReduced)
  end
end
