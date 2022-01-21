defmodule PanWeb.Surface.CategoryButton do
  use Surface.Component
  alias PanWeb.Surface.LinkButton
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Endpoint

  prop(id, :integer, required: false)
  prop(title, :string, required: false)
  prop(class, :string, required: false)
  prop(large, :boolean, required: false, default: false)
  prop(for, :map, required: false)
  prop(index_on_page, :integer, default: 1)
  prop(truncate, :boolean, default: false)

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

  def render(assigns) do
    ~F"""
    <LinkButton to={Routes.category_frontend_path(Endpoint, :show, @id || @for.id)}
                class={color_class_cycle(@index_on_page), @class}
                {=@large}
                icon="folder-heroicons-outline"
                title={@title || @for.title}
                {=@truncate} />
    """
  end
end
