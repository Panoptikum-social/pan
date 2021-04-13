defmodule PanWeb.Surface.Admin.PerPageLink do
  use Surface.Component

  prop(delta, :integer, required: true)
  prop(target, :string, required: true)

  def render(assigns) do
    ~H"""
    <a href="#"
      :on-click={{ "per_page", target: @target }}
      phx-value-delta={{ @delta }}
      class="bg-mint text-white hover:bg-mint-light px-1 py-0.5 lg:px-2 lg:py-1 rounded ml-1 inline-block">
      {{ @delta }}
    </a>
    """
  end
end
