// Import the CSS so that webpack will load it and use the MiniCssExtractPlugin.
// import "../css/app.css"

// Configure module entry points in "webpack.config.js".
// Import deps with the dep name or local files with a relative path, for example:
//     import socket from "./socket"
// Alpine's CSP build: evaluates x-* expressions without eval, so the
// Content-Security-Policy needs no 'unsafe-eval'. It can't reach globals
// (window, Math, localStorage, setTimeout) or run arrow functions in
// templates; code that needs them lives in the components below.
import Alpine from "@alpinejs/csp";
import "phoenix_html";
import { Socket } from "phoenix";
import topbar from "topbar";
import { LiveSocket } from "phoenix_live_view";
import { InfiniteScroll } from "./infinite_scroll";
import { Notification } from "./notification";
import { PodlovePlayer } from "./podlove_player";
import { OvertypeField } from "./overtype_field";
import { LanguageFilterPersistence } from "./language_filter_persistence";
import "./remaining_characters";

// the sidebar starts open on wide screens
Alpine.data("navbar", () => ({
  navbarOpen:
    Math.max(document.documentElement.clientWidth || 0, window.innerWidth || 0) >= 1024,
}));

// the cookie notice on the start page, until it's confirmed once
Alpine.data("cookieConsent", () => ({
  consented: true,
  init() {
    this.consented = localStorage.getItem("cookie_consent") === "true";
  },
  consent() {
    this.consented = true;
    localStorage.setItem("cookie_consent", "true");
  },
}));

// info popovers (podcast and episode metadata, episode and admin grid
// details): the toggle moves the focus to the popover's close button
Alpine.data("metadataToggle", () => ({
  metadataOpen: false,
  toggleMetadata() {
    this.metadataOpen = !this.metadataOpen;
    this.$nextTick(() => this.$refs.metadataCloseButton?.focus());
  },
}));

Alpine.data("detailsToggle", () => ({
  detailsOpen: false,
  toggleDetails() {
    this.detailsOpen = !this.detailsOpen;
    this.$nextTick(() => this.$refs.detailsCloseButton?.focus());
  },
}));

// a notice that hides itself after five seconds (admin sandbox)
Alpine.data("toast", () => ({
  isShow: false,
  show() {
    this.isShow = true;
    setTimeout(() => (this.isShow = false), 5000);
  },
}));

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
  hooks: {
    InfiniteScroll,
    Notification,
    PodloveSubscribeButton,
    PodlovePlayer,
    OvertypeField,
    LanguageFilterPersistence,
  },
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

// Registering a service worker (see priv/static/sw.js) is required by some
// browsers' install criteria for "Add to Home Screen"/desktop
// installability alongside the web manifest.
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/sw.js").catch((error) => {
      console.error("Service worker registration failed:", error);
    });
  });
}
