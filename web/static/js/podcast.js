let Podcast = {
  onReady(socket, podcast_id){
    let podcastChannel = socket.channel("podcasts:" + podcast_id)

    podcastChannel.join()
      .receive("ok",    resp => console.log("joined the podcast channel", resp))
      .receive("error", resp => console.log("join of podcast channel failed", reason))

    podcastChannel.on("like", (resp) =>{
      document.querySelector("[data-type='podcast-like']").outerHTML = resp.button
      this.register_and_show_notify(podcastChannel, resp)
    })

    podcastChannel.on("subscribe", (resp) =>{
      document.querySelector("[data-type='podcast-subscribe']").outerHTML = resp.button
      this.register_and_show_notify(resp)
    })

    podcastChannel.on("follow", (resp) =>{
      document.querySelector("[data-type='podcast-follow']").outerHTML = resp.button
      this.register_and_show_notify(resp)
    })


    this.registerButtons(podcastChannel)
  },


  register_and_show_notify(podcastChannel, message){
    this.registerButtons(podcastChannel)

    $('.top-right').notify({
      type: message.type,
      message: { html: message.content }
    }).show()
  },


  registerButtons(podcastChannel){
    let likeButton = document.querySelector("[data-type='podcast-like']")
    likeButton.addEventListener("click", e => {
      let payload = {podcast_id: likeButton.getAttribute("data-id"),
                     action: likeButton.getAttribute("data-action")}

      podcastChannel.push("like", payload)
                    .receive("error", e => console.log(e))
    })

    let followButton = document.querySelector("[data-type='podcast-follow']")

    followButton.addEventListener("click", e => {
      let payload = {podcast_id: followButton.getAttribute("data-id"),
                     action: followButton.getAttribute("data-action")}

      podcastChannel.push("follow", payload)
                    .receive("error", e => console.log(e))
    })

    let subscribeButton = document.querySelector("[data-type='podcast-subscribe']")
    subscribeButton.addEventListener("click", e => {
      let payload = {podcast_id: subscribeButton.getAttribute("data-id"),
                     action: subscribeButton.getAttribute("data-action")}

      podcastChannel.push("subscribe", payload)
                    .receive("error", e => console.log(e))
    })

  }
}

export default Podcast