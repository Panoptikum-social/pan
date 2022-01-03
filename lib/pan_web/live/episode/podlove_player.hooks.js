import "../../../priv/static/web-player/embed.js"
import "../../../priv/static/web-player/extensions/external-events.js"

let PodlovePlayer = {
  mounted() {
    this.pushEventTo(this.el, "read-config", {}, ({episode, config}, ref) => { 
      window.podlovePlayer("#podlove-player", episode, config)
        .then(registerExternalEvents('podlove-player'));
     })
  }
};

export { PodlovePlayer };
