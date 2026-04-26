let PodlovePlayer = {
  mounted() {
    this.pushEventTo(this.el, "read-config", {}, ({ episode, config }, ref) => {
      window
        .podlovePlayer("#podlove-player", episode, config)
        .then(registerExternalEvents("podlove-player"));
    });
  },
};

export { PodlovePlayer };
