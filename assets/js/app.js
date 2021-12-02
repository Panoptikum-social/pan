// Import the CSS so that webpack will load it and use the MiniCssExtractPlugin.
// import "../css/app.css"

// Configure module entry points in "webpack.config.js".
// Import deps with the dep name or local files with a relative path, for example:
//     import socket from "./socket"
import "alpinejs"
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"
import {InfiniteScroll} from "./infinite_scroll"

let Hooks = {InfiniteScroll}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  dom: {
    onBeforeElUpdated(from, to){
      if(from.__x){ window.Alpine.clone(from.__x, to) }
    }
  },
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})


// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
