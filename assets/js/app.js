// Import the CSS so that webpack will load it and use the MiniCssExtractPlugin.
// import "../css/app.css"

// Configure module entry points in "webpack.config.js".
// Import deps with the dep name or local files with a relative path, for example:
//     import socket from "./socket"
import Alpine from "alpinejs";
import "phoenix_html";
import { Socket } from "phoenix";
import topbar from "topbar";
import { LiveSocket } from "phoenix_live_view";
import { InfiniteScroll } from "./infinite_scroll";
import { Notification } from "./notification";
import { PodlovePlayer } from "./podlove_player";
import { MarkdownField } from "./markdown_field";

window.Alpine = Alpine;
Alpine.start();

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
const PodloveSubscribeButton = {
  mounted() {
    this.pushEventTo(this.el, "read-config", {}, (resp, ref) => {
      window['podcastData'] = resp;
      const scripttag = document.createElement('script');
      scripttag.async = true;
      scripttag.src = '/subscribe-button/javascripts/app.js';
      scripttag.setAttribute('class', 'podlove-subscribe-button');
      scripttag.setAttribute('data-language', 'en');
      scripttag.setAttribute('data-size', 'medium');
      scripttag.setAttribute('data-json-data', 'podcastData');
      scripttag.setAttribute('data-color', '#ED5565');
      scripttag.setAttribute('data-format', 'rectangle');
      scripttag.setAttribute('data-style', 'filled');
      this.el.appendChild(scripttag);
    });
  },
};

let liveSocket = new LiveSocket("/live", Socket, {
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to);
      }
    },
  },
  hooks: { InfiniteScroll, Notification, PodloveSubscribeButton, PodlovePlayer, MarkdownField },
  params: { _csrf_token: csrfToken }
});

// Show progress bar on live navigation and form submits
// Show progress bar on live navigation and form submits
topbar.config({
  barColors: { 0: "#ffce54" },
  shadowColor: "rgba(0, 0, 0, .3)",
});
let topBarScheduled = undefined;

window.addEventListener("phx:page-loading-start", () => {
  if (!topBarScheduled) {
    topBarScheduled = setTimeout(() => topbar.show(), 400);
  }
});

window.addEventListener("phx:page-loading-stop", () => {
  clearTimeout(topBarScheduled);
  topBarScheduled = undefined;
  topbar.hide();
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
