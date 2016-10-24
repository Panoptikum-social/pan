defmodule Pan.Parser.EP do
  import SweetXml

  def parse(xml) do
   episodes =
     xml
     |> xpath(~x"//channel/item"l)
     |> Enum.map( fn (episode) ->
       %{
         contributors:  episode
                        |> xpath(~x"atom:contributor"l,
                                 name: ~x"./atom:name/text()"s,
                                 uri: ~x"./atom:uri/text()"s),
         chapters: episode
                   |> xpath(~x"psc:chapters/psc:chapter"l,
                            start: ~x"./@start"s,
                            title: ~x"./@title"s),
       }
     end)
  end
end