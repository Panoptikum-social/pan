defmodule Pan.Parser.Helpers do
  alias Pan.Language
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
    {:ok, Repo.get_by(Language, shortcode: shortcode)}
  end


  def to_ecto_datetime(feed_date) do
    {:ok, datetime} = Timex.parse(feed_date, "{RFC1123}")

    erltime = Timex.to_erl(datetime)
    # why can't I pipe here?
    Ecto.DateTime.from_erl(erltime)
  end
end