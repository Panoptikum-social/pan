defmodule PanWeb.Live.IconTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  alias PanWeb.Live.Icon

  test "renders an outline icon inline with the given class and no fixed size" do
    svg = Icon.to_string("microphone", class: "size-5 text-primary")

    assert svg =~ ~r/\A<svg class="size-5 text-primary" xmlns=/
    assert svg =~ ~s(stroke="currentColor")
    assert svg =~ ~s(stroke-width="2")
    refute svg =~ ~r/\s(width|height)=/
    refute svg =~ "icon-tabler"
  end

  test "renders a filled icon by its -filled name" do
    assert Icon.to_string("heart-filled", class: "size-4") =~ ~s(fill="currentColor")
  end

  test "escapes the class" do
    assert Icon.to_string("x", class: ~s(a" onload="b)) =~ ~s(class="a&quot; onload=&quot;b")
  end

  test "unknown names and names outside the icon directory render nothing" do
    for name <- ["no-such-icon", "../../../mix", "Microphone", nil] do
      assert capture_log(fn -> assert Icon.to_string(name, class: "") == "" end) =~
               "Unknown icon"
    end
  end
end
