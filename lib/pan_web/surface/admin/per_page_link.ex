defmodule PanWeb.Surface.Admin.PerPageLink do
  use Surface.Component

  prop(delta, :integer, required: true)
  prop(target, :string, required: true)

  def render(assigns) do
    ~H"""
    <a href="#"
      :on-click={{ "per_page", target: @target }}
      phx-value-delta={{ @delta }}
      class="bg-mint text-white hover:bg-mint-light px-2 py-0.5 rounded ml-2 inline-block">
      {{ @delta }}
    </a>
    """
  end
end
