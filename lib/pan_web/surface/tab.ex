defmodule PanWeb.Surface.Tab do
  use Surface.Component

  prop items, :list, required: true

  slot default, props: [item: ^items]

  def render(assigns) do
    ~H"""
    <div x-data="{ selectedTab: 0 }">
      <ul class="flex flex-wrap border-b mt-0.5" >
        <li :for.index={{ @items }}
            class="-mb-px mr-1 bg-gray-200 text-gray-500">
          <a class="inline-block rounded-t py-2 px-4 font-semibold hover:text-blue-800"
            :class="{ 'bg-white text-black border-l border-t border-r' : selectedTab === {{ index }} }"
            @click.prevent="selectedTab = {{ index }}"
            href="#">
            {{ index + 1 }}
          </a>
        </li>
      </ul>
      <div class="content bg-white px-4 py-4 border-l border-r border-b pt-4">
        <div :for.with_index={{ {item, index} <- @items }}
             x-show="selectedTab === {{ index }}">
          <slot :props={{ item: item }} />
        </div>
      </div>
    </div>
    """
  end
end
