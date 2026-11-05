defmodule PanWeb.Blog do
  @moduledoc """
  Links to the qed site blog.panoptikum.social (About, Manuals, legal pages,
  #586). German users get the German page under /de/ where one exists; the
  blog and the API docs are English only.
  """

  @base "https://blog.panoptikum.social"

  # pages with a German translation on the qed site (pages/*.de.md)
  @translated ~w(
    /
    /code-of-conduct/
    /community/
    /complaints/
    /imprint/
    /manuals/
    /manuals/listener-manual/
    /manuals/podcaster-manual/
    /manuals/moderator-manual/
    /manuals/curator-manual/
    /no-more-pro/
    /privacy/
    /talks/
  )

  def url(path) do
    case Gettext.get_locale(PanWeb.Gettext) do
      "de" when path in @translated -> @base <> "/de" <> path
      _other -> @base <> path
    end
  end
end
