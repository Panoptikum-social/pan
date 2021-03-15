defmodule PanWeb.Live.Category.Show do
  use Surface.LiveView
  import PanWeb.Router.Helpers
  alias PanWeb.Category
  alias PanWeb.Surface.{Panel, PanelHeading, Icon}

  def mount(%{"id" => id}, _session, socket) do
    case Category.by_id_exists?(id) do
      true -> {:ok, assign(socket, Category.get_with_children_parent_and_podcasts(id))}
      false -> {:ok, assign(socket, error: "not_found")}
    end
  end

  def render(%{error: "not_found"} = assigns) do
    ~H"""
    <div class="m-12">
      A category with this id could not be found
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="m-4">
      <Panel purpose="category">
        <PanelHeading>
          <a href={{ category_frontend_path(@socket, :index) }}
            class="hover:text-blue-400">
            <Icon name="folder" /> Panoptikum
          </a> /
          <If condition={{ @category.parent }}>
            <a href={{ category_frontend_path(@socket, :show, @category.parent) }}
              class="hover:text-blue-400">
              <Icon name="folder" /> Panoptikum
            </a> /
          </If>
          <Icon name="folder-open" /> {{ @category. title }}
        </PanelHeading>

        panel-body
      </Panel>
    </div>
    """
  end
end
