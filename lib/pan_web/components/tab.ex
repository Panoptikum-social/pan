defmodule PanWeb.Component.Tab do
  # Not used anywhere yet — kept for a future feature. See conversation from 2026-08-21.
  use PanWeb, :html

  attr :items, :list, required: true

  slot :inner_block, required: true

  def render(assigns) do
    ~H"""
    <div x-data="{ selectedTab: 0 }" class="pt-0.5">
      <ul class="flex flex-wrap border-b border-base-300">
        <%= for {_item, index} <- Enum.with_index(@items) do %>
          <li class="-mb-px ml-1.5">
            <a
              class="inline-block rounded-t px-2 py-1.5 hover:text-primary border-base-300"
              x-bind:class={"{ 'disabled font-semibold text-base-content bg-base-100 border-l border-t border-r' : selectedTab === #{index}, 'bg-base-300 text-base-content/70' : selectedTab !== #{index} }"}
              @click.prevent={"selectedTab = #{index}"}
              to="#"
            >{index + 1}</a>
          </li>
        <% end %>
      </ul>
      <div class="p-4">
        <%= for {item, index} <- Enum.with_index(@items) do %>
          <div x-show={"selectedTab === #{index}"}>
            {render_slot(@inner_block, item)}
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
