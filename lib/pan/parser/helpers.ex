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


  # Deep merging maps
  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end

  defp deep_resolve(_key, left, right) do
    right
  end
end