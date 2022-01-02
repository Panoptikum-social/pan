import podlovePlayer from "../../../priv/static/web-player/embed.js"

let PodlovePlayer = {
  mounted(){
    window.podlovePlayer("#podlove-player", episode, config);
  }
};

export {PodlovePlayer};