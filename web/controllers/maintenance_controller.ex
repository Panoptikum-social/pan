defmodule Pan.MaintenanceController do
  use Pan.Web, :controller

  def vienna_beamers(conn, _params) do
    redirect(conn, external: "https://blog.panoptikum.io/vienna-beamers/")
  end

  def blog_2016(conn, %{"month" => month, "day" => day, "file" => file}) do
    redirect(conn, external: "https://blog.panoptikum.io/2016/#{month}/#{day}/#{file}")
  end

  def blog_2017(conn, %{"month" => month, "day" => day, "file" => file}) do
    redirect(conn, external: "https://blog.panoptikum.io/2017/#{month}/#{day}/#{file}")
  end


  def fix(conn, _params) do
    from(a in Pan.AlternateFeed, where: a.url == ^"http://reachmd.com/")
    |> Repo.delete_all()

    alternate_feeds = from(a in Pan.AlternateFeed, where: like(a.url, "https://reachmd.com/%"),
                                                   preload: :feed)
                      |> Repo.all()

    for alternate_feed <- alternate_feeds do
      Pan.Feed.changeset(alternate_feed.feed, %{self_link_url: alternate_feed.url})
      |> Repo.update()
    end

    from(a in Pan.AlternateFeed, where: like(a.url, "https://reachmd.com/%"))
                                 |> Repo.delete_all()

    render(conn, "done.html", %{})
  end
end
