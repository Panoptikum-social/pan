defmodule Pan.MaintenanceController do
  use Pan.Web, :controller
  alias Pan.Episode

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
    podcasts = from(e in Episode, join: p in assoc(e, :podcast),
                                  group_by: p.id,
                                  select: %{id: p.id,
                                            title: p.title,
                                            last_episode: max(e.publishing_date),
                                            last_build_date: p.last_build_date})
               |> Repo.all

    render(conn, "fix.html", podcasts: podcasts)
  end
end
