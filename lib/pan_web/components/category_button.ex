defmodule PanWeb.Component.CategoryButton do
  use PanWeb, :html
  alias PanWeb.Component.LinkButton
  alias PanWeb.Router.Helpers, as: Routes
  alias PanWeb.Endpoint

  # {solid, light tint} per color, spelled out so Tailwind picks the classes
  # up. The tint is for subcategories, in the color of their parent.
  @colors [
    {"bg-success hover:bg-success-light text-white",
     "bg-success/15 hover:bg-success/30 border-success text-gray-darker"},
    {"bg-mint hover:bg-mint-light text-white",
     "bg-mint/15 hover:bg-mint/30 border-mint text-gray-darker"},
    {"bg-info hover:bg-info-light text-white",
     "bg-info/15 hover:bg-info/30 border-info text-gray-darker"},
    {"bg-blue-jeans hover:bg-blue-jeans-light text-white",
     "bg-blue-jeans/15 hover:bg-blue-jeans/30 border-blue-jeans text-gray-darker"},
    {"bg-lavender hover:bg-lavender-light text-white",
     "bg-lavender/15 hover:bg-lavender/30 border-lavender text-gray-darker"},
    {"bg-pink-rose hover:bg-pink-rose-light text-white",
     "bg-pink-rose/15 hover:bg-pink-rose/30 border-pink-rose text-gray-darker"},
    {"bg-danger hover:bg-danger-light text-white",
     "bg-danger/15 hover:bg-danger/30 border-danger text-gray-darker"},
    {"bg-bittersweet hover:bg-bittersweet-light text-white",
     "bg-bittersweet/15 hover:bg-bittersweet/30 border-bittersweet text-gray-darker"},
    {"bg-warning hover:bg-warning-light text-white",
     "bg-warning/15 hover:bg-warning/30 border-warning text-gray-darker"}
  ]

  # without a position on the page (category tags on podcast pages and the
  # like) the button stays neutral
  defp color_class(nil, _tint),
    do: "bg-gray-lighter hover:bg-gray-lightest text-gray-darker border-gray"

  defp color_class(index, tint) do
    {solid, light} = Enum.at(@colors, rem(index, length(@colors)))
    if tint, do: light, else: solid
  end

  attr :id, :integer, default: nil
  attr :title, :string, default: nil
  attr :class, :string, default: nil
  attr :large, :boolean, default: false
  attr :for, :map, default: nil
  attr :index_on_page, :integer, default: nil
  attr :tint, :boolean, default: false, doc: "light tint of the color, for subcategories"
  attr :truncate, :boolean, default: false

  def render(assigns) do
    ~H"""
    <LinkButton.render
      to={Routes.category_frontend_path(Endpoint, :show, @id || @for.id)}
      class={[color_class(@index_on_page, @tint), @class]}
      large={@large}
      icon="folder-heroicons-outline"
      title={@title || @for.title}
      truncate={@truncate}
    />
    """
  end
end
