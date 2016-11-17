let Podcast = {
  onReady(socket, podcastButton){
    let podcastChannel = socket.channel("podcasts:" + podcastButton.getAttribute("data-id"))

    podcastChannel.join()
      .receive("ok",    resp => console.log("joined the podcast channel", resp))
      .receive("error", resp => console.log("join of podcast channel failed", reason))

    podcastChannel.on("like", (resp) =>{
      podcastButton.outerHTML = resp.button

      //reregistering the event handler, because we have a new button
      podcastButton = document.querySelector("[data-type='podcast']")
      this.registerButton(podcastChannel, podcastButton)

      $('.top-right').notify({
        type: resp.type,
        message: { html: resp.content }
      }).show();
    })

    this.registerButton(podcastChannel, podcastButton)
  },


  registerButton(podcastChannel, podcastButton){
    podcastButton.addEventListener("click", e => {
      let payload = {podcast_id: podcastButton.getAttribute("data-id"),
                     action: podcastButton.getAttribute("data-action")}

      podcastChannel.push("like", payload)
                    .receive("error", e => console.log(e))
    })
  }
}

export default Podcast