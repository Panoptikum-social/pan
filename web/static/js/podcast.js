let Podcast = {
  onReady(socket, podcast_id){
    let podcastChannel = socket.channel("podcasts:" + podcast_id)

    podcastChannel.join()
      .receive("ok",    response => console.log("joined podcast:" + podcast_id, response))
      .receive("error", response => console.log("join of podcast:" + podcast_id + " failed", reason))

    this.registerButtons(podcastChannel)

    Array.from(document.querySelectorAll("[data-type='podcast']")).forEach(button => {
      let event = button.dataset.event

      podcastChannel.on(event, (response) =>{
        let button = document.querySelector("[data-type='podcast'][data-event='" + event + "']")
        button.outerHTML = response.button
        this.registerButtons(podcastChannel)

        $('.top-right').notify({
          type: response.type,
          response: { html: response.content }
        }).show()
      })
    })
  },

  registerButtons(podcastChannel){
    Array.from(document.querySelectorAll("[data-type='podcast']")).forEach(button => {
      button.addEventListener("click", e => {
        let payload = {podcast_id: button.dataset.id,
                       action: button.dataset.action}

        podcastChannel.push(button.dataset.event, payload)
                      .receive("error", e => console.log(e))
      })
    })
  }
}

export default Podcast