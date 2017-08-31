defmodule Pan.PodcastApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "podcast"

  location "https://panoptikum.io/jsonapi/categories/:id"
  attributes [:title, :website, :description, :summary, :image_title, :image_url, :last_build_date,
              :payment_link_title, :payment_link_url, :explicit, :update_paused, :blocked,
              :update_paused, :update_intervall, :next_update, :retired, :unique_identifier]

end

defmodule Pan.PlainPodcastApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "podcast"

  location "https://panoptikum.io/jsonapi/categories/:id"
  attributes [:title, :website, :description, :summary, :image_title, :image_url, :last_build_date,
              :payment_link_title, :payment_link_url, :explicit, :update_paused, :blocked,
              :update_paused, :update_intervall, :next_update, :retired, :unique_identifier]
end


defmodule Pan.ReducedPodcastApiView do
  use Pan.Web, :view
  use JaSerializer.PhoenixView

  def type(_, _), do: "podcast"

  location "https://panoptikum.io/jsonapi/categories/:id"
  attributes [:title, :website, :description, :image_title, :image_url]
end
