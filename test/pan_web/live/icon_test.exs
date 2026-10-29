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

  test "adds the icon's own color unless the class sets a text color" do
    assert Icon.to_string("calendar", class: "size-5 text-sm") =~
             ~s(class="size-5 text-sm text-ctp-blue")

    assert Icon.to_string("calendar", class: "size-5 text-podcast") =~
             ~s(class="size-5 text-podcast")

    assert Icon.to_string("podium", class: "size-5") =~ ~s(class="size-5")
  end

  test "renders a filled icon by its -filled name" do
    assert Icon.to_string("heart-filled", class: "size-4") =~ ~s(fill="currentColor")
  end

  test "escapes the class" do
    assert Icon.to_string("podium", class: ~s(a" onload="b)) =~ ~s(class="a&quot; onload=&quot;b")
  end

  test "unknown names and names outside the icon directory render nothing" do
    for name <- ["no-such-icon", "../../../mix", "Microphone", nil] do
      assert capture_log(fn -> assert Icon.to_string(name, class: "") == "" end) =~
               "Unknown icon"
    end
  end

  test "exists? only for names of vendored icons" do
    assert Icon.exists?("microphone")
    assert Icon.exists?("heart-filled")
    refute Icon.exists?("no-such-icon")
    refute Icon.exists?("../../../mix")
    refute Icon.exists?(nil)
  end
end
