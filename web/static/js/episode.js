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
                                message: { html: "<i>" + response.user_name + ":</i> &nbsp;" +
                                                 response.content } }).show()
      })
    })

    Array.from(document.querySelectorAll("[data-type='chapter']")).forEach(button => {
      let event = button.dataset.event
      this.listen_to_chapter(episodeChannel, button.dataset.id)
    })

    episodeChannel.on("like-chapter", (response) =>{
      var button = document.querySelector("[data-type='chapter']" +
                                          "[data-event='like-chapter']" +
                                          "[data-id='" + response.chapter_id + "']")
      button.outerHTML = response.button
      this.listen_to_chapter(episodeChannel, response.chapter_id.toString())
      $('.top-right').notify({type: response.type,
                              message: { html: "<i>" + response.user_name + ":</i>  &nbsp;" +
                                               response.content } }).show()
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
  },


  listen_to_chapter(episodeChannel, chapter_id) {
    var button = document.querySelector("[data-type='chapter']" +
                                        "[data-event='like-chapter']" +
                                        "[data-id='" + chapter_id + "']")
    button.addEventListener("click", e => {
      let payload = {chapter_id: chapter_id,
                     action: button.dataset.action}

      episodeChannel.push(button.dataset.event, payload)
                    .receive("error", e => console.log(e))
    })
  }
}

export default Episode