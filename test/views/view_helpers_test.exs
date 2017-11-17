defmodule Pan.ViewHelpersTest do
  use ExUnit.Case, async: true

  alias PanWeb.ViewHelpers

  describe "truncate" do
    test "doesn't do anything for short strings" do
      assert "brief" == ViewHelpers.truncate("brief", 10)
    end

    test "truncates long strings" do
      assert "loooooo..." == ViewHelpers.truncate("looooooooong", 10)
    end
  end
end
