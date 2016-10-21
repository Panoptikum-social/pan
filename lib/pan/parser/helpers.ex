defmodule Pan.Parser.Helpers do
  use Pan.Web, :controller

  def boolify(explicit) do
    case explicit do
      "yes" ->
        true
      _ ->
        false
    end
  end


  def find_language(shortcode) do
    {:ok, Repo.get_by(Pan.Language, shortcode: shortcode)}
  end


  def to_ecto_datetime(feed_date) do
    {:ok, datetime} = Timex.parse(feed_date, "{RFC1123}")

    erltime = Timex.to_erl(datetime)
    # why can't I pipe here?
    Ecto.DateTime.from_erl(erltime)
  end


  def fix_missing_xml_tag(xml) do
    xml =
      if String.starts_with?(xml, ["<?xml"]) do
        xml
      else
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" <> xml
      end

    {:ok, xml}
  end
end