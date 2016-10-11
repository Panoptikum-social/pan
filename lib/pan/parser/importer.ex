defmodule Pan.Parser.Importer do
  import SweetXml

  def print_generators() do
    stream = File.stream!("materials/feeds.xml", [:read, :utf8])
    Enum.each(stream, fn(url) -> print_generator(url) end)
  end

  def print_generator(url) do
    try do
      %HTTPoison.Response{body: xml} = HTTPoison.get!(url, [], [follow_redirect: true])
      feed_generator = xml |> xpath(~x"//channel/generator/text()"s)
      if String.contains?(feed_generator, "odlove") do
        IO.puts(url <> "     ")
      else
        IO.puts "-"
      end
    catch
      :exit, _ ->  IO.puts "ex"
      :timeout, _ -> IO.puts "t"
      :error, _ -> IO.puts "er"
    end
  end

  def mass_import() do
    stream = File.stream!("materials/feeds.xml", [:read, :utf8])
    Enum.each(stream, fn(url) -> Pan.Parser.import_feed(url) end)
  end
end