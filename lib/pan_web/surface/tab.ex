defmodule PanWeb.Surface.Tab do
  use Surface.Component

  prop(items, :generator, required: true)

  slot(default, generator_prop: :items)

  def render(assigns) do
    ~F"""
    <div x-data="{ selectedTab: 0 }" class="pt-0.5">
      <ul class="flex flex-wrap border-b border-gray-lighter">
        {#for {_item, index} <- @items |> Enum.with_index}
          <li class="-mb-px ml-1.5">
            <a class="inline-block rounded-t px-2 py-1.5 hover:text-link-dark border-gray-lighter"
              :class={"{ 'disabled font-semibold text-gray bg-white border-l border-t border-r text-gray-darker' :
                          selectedTab === #{index},
                        'bg-gray-lighter text-gray-dark' :
                        selectedTab !== #{index} }"}
              @click.prevent={"selectedTab = #{index}"}
              to="#">{index + 1}</a>
          </li>
        {/for}
      </ul>
      <div class="p-4">
        {#for {item, index} <- @items |> Enum.with_index}
          <div x-show={"selectedTab === #{index}"}>
            <#slot generator_value={item} {@default} />
          </div>
        {/for}
      </div>
    </div>
    """
  end
end
