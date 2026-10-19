defmodule PanWeb.UploadTest do
  use ExUnit.Case, async: true

  alias PanWeb.Upload

  test "a plain filename is kept" do
    assert Upload.safe_filename("subscriptions.opml") == "subscriptions.opml"
  end

  test "path segments sent by the client are dropped" do
    assert Upload.safe_filename("../../../home/phoenix/.ssh/authorized_keys") == "authorized_keys"
    assert Upload.safe_filename("/etc/passwd") == "passwd"
    assert Upload.safe_filename("dir/sub/feeds.opml") == "feeds.opml"
  end

  test "names that aren't a file get a neutral name" do
    assert Upload.safe_filename("") == "upload"
    assert Upload.safe_filename(".") == "upload"
    assert Upload.safe_filename("..") == "upload"
    assert Upload.safe_filename("../") == "upload"
  end
end
