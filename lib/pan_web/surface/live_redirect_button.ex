defmodule PanWeb.Surface.LiveRedirectButton do
  use Surface.Component
  alias PanWeb.Surface.Icon
  alias Surface.Components.LiveRedirect

  prop(id, :string, required: false)
  prop(title, :string, required: true)
  prop(to, :fun, required: true)
  prop(class, :css_class, required: false)
  prop(large, :boolean, required: false, default: false)
  prop(icon, :string, required: false)
  prop(truncate, :boolean, default: false)
  prop(method, :atom, default: :get)
  prop(opts, :keyword, default: [])

  def render(assigns) do
    ~F"""
    <LiveRedirect to={@to}
                  class={"border border-solid inline-block shadow",
                        @class,
                        "truncate max-w-full": @truncate,
                        "py-1 px-2 rounded text-sm": !@large,
                        "py-2 px-3 rounded-md": @large}
                  {=@opts}>
        <Icon :if={@icon} name={@icon} spaced/>
        {@title}
    </LiveRedirect>
    """
  end
end
