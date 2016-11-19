let Episode = {
  onReady(socket, episode_id){
    let episodeChannel = socket.channel("episodes:" + episode_id)

    episodeChannel.join()
      .receive("ok",    response => {
        console.log("joined episode:" + episode_id, response)
      })
      .receive("error", response => {
        console.log("join of episode:" + episode_id + " failed", reason)
      })

    Array.from(document.querySelectorAll("[data-type='episode']")).forEach(button => {
      let event = button.dataset.event
      this.listen_to(event, episodeChannel)

      episodeChannel.on(event, (response) =>{
        var button = document.querySelector("[data-type='episode']" +
                                            "[data-event='" + event + "']")
        button.outerHTML = response.button
        this.listen_to(event, episodeChannel)
        $('.top-right').notify({type: response.type,
                                message: { html: response.content } }).show()
      })
    })
  },


  listen_to(event, episodeChannel) {
    var button = document.querySelector("[data-type='episode']" +
                                        "[data-event='" + event + "']")
    button.addEventListener("click", e => {
      let payload = {episode_id: button.dataset.id,
                     action: button.dataset.action}

      episodeChannel.push(button.dataset.event, payload)
                    .receive("error", e => console.log(e))
    })
  }
}

export default Episode