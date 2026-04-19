defmodule PanWeb.Surface.Pill do
  use PanWeb, :html

  attr :type, :string, default: "info"
  attr :id, :string, default: nil
  attr :large, :boolean, default: false

  slot :inner_block, required: true

  def render(assigns) do
    ~H"""
    <span class={[
            "inline-block leading-none text-center whitespace-nowrap align-baseline text-white",
            "bg-#{@type} hover:bg-#{@type}-dark",
            !@large && "p-1 rounded-md text-xs",
            @large && "py-2 px-3 rounded-xl text-sm"
          ]}
          id={@id}>
      {render_slot(@inner_block)}
    </span>
    """
  end
end
