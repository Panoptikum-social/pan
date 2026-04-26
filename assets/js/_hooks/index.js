function ns(hooks, nameSpace) {
  const updatedHooks = {}
  Object.keys(hooks).map(function(key) {
    updatedHooks[`${nameSpace}#${key}`] = hooks[key]
  })
  return updatedHooks
}

import * as c1 from "./PanWeb.Live.Episode.PodlovePlayer.hooks"
import * as c2 from "./PanWeb.Live.Podcast.PodloveSubscribeButton.hooks"
import * as c3 from "./PanWeb.Surface.MarkdownField.hooks"

let hooks = Object.assign(
  ns(c1, "PanWeb.Live.Episode.PodlovePlayer"),
  ns(c2, "PanWeb.Live.Podcast.PodloveSubscribeButton"),
  ns(c3, "PanWeb.Surface.MarkdownField")
)

export default hooks
