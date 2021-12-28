defmodule PanWeb.Surface.Pill do
  use Surface.Component
  prop type, :string, required: false, default: "info", values!: ["link", "info", "primary", "warning", "danger", "success", "lavender"]
  prop id, :string, required: false
  prop large, :boolean, default: false
  slot default, required: true

  def render(assigns) do
    ~F"""
    <span class={"inline-block eading-none text-center whitespace-nowrap
                 align-baseline bg-#{@type} hover:bg-#{@type}-dark text-white",
                 "p-1 rounded-md text-xs": !@large,
                 "py-2 px-3 rounded-xl text-sm": @large}
          id={@id}>
      <#slot />
    </span>
    """
  end
end
