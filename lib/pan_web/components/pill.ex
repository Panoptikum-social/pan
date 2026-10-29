defmodule PanWeb.Component.Pill do
  use PanWeb, :html

  # roles and labels as outline badges: the color in the frame, the text in
  # the text color (DESIGN.md); literal classes, so Tailwind generates them
  @badges %{
    "success" => "badge-success",
    "lavender" => "badge-secondary",
    "info" => "badge-info"
  }

  attr :type, :string, default: "info"
  attr :id, :string, default: nil
  attr :large, :boolean, default: false

  slot :inner_block, required: true

  def render(assigns) do
    assigns = assign(assigns, :badge, Map.get(@badges, assigns.type, "badge-neutral"))

    ~H"""
    <span class={["badge badge-outline whitespace-nowrap", @badge, !@large && "badge-sm"]} id={@id}>
      {render_slot(@inner_block)}
    </span>
    """
  end
end
