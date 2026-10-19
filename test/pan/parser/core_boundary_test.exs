defmodule Pan.Parser.CoreBoundaryTest do
  @moduledoc """
  The parsing core (Project #1, phase 1 in backlog.md): XML in, the parser's
  map out, no database. Checked on the compiled modules, so a Repo call or a
  PanWeb model sneaking into one of them fails here.
  """
  use ExUnit.Case, async: true

  @core [
    Pan.Parser.Analyzer,
    Pan.Parser.Download,
    Pan.Parser.FeedXml,
    Pan.Parser.Helpers,
    Pan.Parser.Iterator,
    Pan.Parser.Leniency,
    Pan.Parser.MyDateTime,
    Pan.Parser.SsrfGuard,
    Pan.Parser.XmlNames
  ]

  defp called_modules(module) do
    {:ok, {_module, [imports: imports]}} = :beam_lib.chunks(:code.which(module), [:imports])
    imports |> Enum.map(&elem(&1, 0)) |> Enum.uniq()
  end

  defp app_or_ecto?(module) do
    name = inspect(module)
    String.starts_with?(name, ["Pan.", "PanWeb.", "Ecto."]) or name in ["Pan", "PanWeb"]
  end

  for module <- @core do
    test "#{inspect(module)} calls no app or Ecto module outside the core" do
      outside =
        unquote(module)
        |> called_modules()
        |> Enum.filter(&app_or_ecto?/1)
        |> Enum.reject(&(&1 in @core))

      assert outside == []
    end
  end
end
