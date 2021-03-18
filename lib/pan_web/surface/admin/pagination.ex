defmodule PanWeb.Surface.Admin.Pagination do
  use Surface.Component
  alias PanWeb.Surface.Admin.PaginationLink

  prop per_page, :integer
  prop current_page, :integer

  def render(assigns) do
    ~H"""
    <div class="pb-6">
      <PaginationLink :if={{ @current_page > 1 }}
                      page={{ @current_page - 1 }}
                      per_page={{ @per_page}}>
        Previous
      </PaginationLink>

      <PaginationLink :for={{ i <- 1..@current_page }}
                      disabled={{ i == @current_page }}
                      page={{ i }}
                      per_page={{ @per_page }}>
        {{ i }}
      </PaginationLink>

      <PaginationLink page={{ @current_page + 1 }}
                      per_page={{ @per_page }}>
        Next
      </PaginationLink>
    </div>
    """
  end
end
