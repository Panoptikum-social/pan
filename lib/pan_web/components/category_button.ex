defmodule PanWeb.Component.CategoryButton do
  use PanWeb, :html
  alias PanWeb.Component.LinkButton
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Endpoint

  defp color_class_cycle(counter) do
    Enum.at(
      [
        "bg-white hover:bg-gray-lighter text-gray-darker border-gray",
        "bg-gray-lighter hover:bg-gray-lightest text-gray-darker border-gray",
        "bg-gray hover:bg-gray-light text-white",
        "bg-gray-darker hover:bg-gray-darker text-white",
        "bg-success hover:bg-success-light text-white",
        "bg-mint hover:bg-mint-light text-white",
        "bg-info hover:bg-info-light text-white",
        "bg-blue-jeans hover:bg-blue-jeans-light text-white",
        "bg-lavender hover:bg-lavender-light text-white",
        "bg-pink-rose hover:bg-pink-rose-light text-white",
        "bg-danger hover:bg-danger-light text-white",
        "bg-bittersweet hover:bg-bittersweet-light text-white",
        "bg-warning hover:bg-warning-light text-white"
      ],
      rem(counter, 13)
    )
  end

  attr :id, :integer, default: nil
  attr :title, :string, default: nil
  attr :class, :string, default: nil
  attr :large, :boolean, default: false
  attr :for, :map, default: nil
  attr :index_on_page, :integer, default: 1
  attr :truncate, :boolean, default: false

  def render(assigns) do
    ~H"""
    <LinkButton.render to={Routes.category_frontend_path(Endpoint, :show, @id || @for.id)}
                       class={[color_class_cycle(@index_on_page), @class]}
                       large={@large}
                       icon="folder-heroicons-outline"
                       title={@title || @for.title}
                       truncate={@truncate} />
    """
  end
end
