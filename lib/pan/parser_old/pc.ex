defmodule Pan.Parser.PC do
  use Pan.Web, :controller
  alias Pan.Podcast
  alias Pan.Parser.Helpers
  import SweetXml

  def parse(xml) do
    explicit = xml
               |> xpath(~x"//channel/itunes:iexplicit/text()"s)
               |> Helpers.boolify


    podcast = %Podcast{explicit: explicit}
  end
end