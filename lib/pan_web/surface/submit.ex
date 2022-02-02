defmodule PanWeb.Surface.Submit do
  use Surface.Component
  alias Surface.Components.Form

  prop(label, :string, required: false, default: "Submit")

  prop(class, :css_class,
    required: false,
    default: "mt-4 py-2 px-4 rounded-lg font-medium text-white bg-aqua hover:bg-aqua-light"
  )

  def render(assigns) do
    ~F"""
    <Form.Submit {=@label}
                 {=@class} />
    """
  end
end
