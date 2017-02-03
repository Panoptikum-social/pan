defmodule Pan.ViewHelpers do
  def btn_cycle(counter) do
    Enum.at(["btn-default", "btn-light-gray", "btn-medium-gray", "btn-dark-gray",
             "btn-success", "btn-info", "btn-primary", "btn-blue-jeans", "btn-lavender",
             "btn-pink-rose", "btn-danger", "btn-bittersweet", "btn-warning", ], rem(counter, 13))
  end
end