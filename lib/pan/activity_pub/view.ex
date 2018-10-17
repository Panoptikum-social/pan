defmodule Pan.ActivityPub.View do
  use Pan.Web, :view

  def published(toot) do
    {:ok, datetime} = toot["published"]
                      |> NaiveDateTime.from_iso8601()
    Timex.format!(datetime, "{ISOdate} {h24}:{m}")
  end

  def content(toot) do
    object = toot["object"]

    if is_binary(object) do
      object
    else
      raw(object["content"])
    end
  end
end