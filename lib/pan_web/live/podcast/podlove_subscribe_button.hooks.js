import "../../../priv/static/subscribe-button/javascripts/app.js"

let PodloveSubscribeButton = {
  mounted() {
    this.pushEventTo(this.el, "read-config", {}, (data, ref) => { 
      // initi with data
     })
  }
};

export { PodloveSubscribeButton };
