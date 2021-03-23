defmodule PanWeb.Surface.Admin.Pagination do
  use Surface.Component
  alias PanWeb.Surface.Admin.PaginationLink

  prop(per_page, :integer, required: false, default: 10)
  prop(current_page, :integer, required: false, default: 1)
  prop(class, :css_class, required: false)
  prop(target, :string, required: true)

  def render(assigns) do
    ~H"""
    <div class={{"pb-6", @class}}>
      <PaginationLink :if={{ @current_page > 1 }}
                      page={{ @current_page - 1 }}
                      per_page={{ @per_page}}
                      class="rounded-l-lg"
                      target={{ @target }} >
        Previous
      </PaginationLink>
      &nbsp;
      <PaginationLink :for={{ i <- 1..@current_page }}
                      disabled={{ i == @current_page }}
                      page={{ i }}
                      per_page={{ @per_page }}
                      class={{ "rounded-l-lg": i==1 }}
                      target={{ @target }} >
        {{ i }}
      </PaginationLink>
      &nbsp;
      <PaginationLink page={{ @current_page + 1 }}
                      per_page={{ @per_page }}
                      class="rounded-r-lg"
                      target={{ @target }} >
        Next
      </PaginationLink>
    </div>
    """
  end
end
