defmodule PanWeb.Surface.Pill do
  use Surface.Component
  prop type, :string, required: false, default: "info", values!: ["link", "info", "primary", "warning", "danger", "success"]
  slot default, required: true

  def render(assigns) do
    ~F"""
    <span class={"text-xs inline-block p-1 leading-none text-center whitespace-nowrap
                 align-baseline rounded-md bg-#{@type} hover:bg-#{@type}-dark text-white"}>
      <#slot />
    </span>
    """
  end
end
