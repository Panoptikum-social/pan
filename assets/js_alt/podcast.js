import Notification from "./notification"

let Podcast = {
  onReady(socket, podcast_id){
    let podcastChannel = socket.channel("podcasts:" + podcast_id)

    podcastChannel.join()
      .receive("ok", response => {
        console.log("joined podcast:" + podcast_id, response)
      })
      .receive("error", response => {
        console.log("join of podcast:" + podcast_id + " failed", reason)
      })

    podcastChannel.on("notification", (response) => Notification.popup(response) )

    Array.from(document.querySelectorAll("[data-type='podcast']")).forEach(button => {
      this.listen_to(button.dataset.event, podcastChannel)
    })
  },


  listen_to(event, podcastChannel) {
    var button = document.querySelector("[data-type='podcast']" +
                                        "[data-event='" + event + "']")
    button.addEventListener("click", e => {
      let payload = {podcast_id: button.dataset.id, action: button.dataset.action}
      podcastChannel.push(button.dataset.event, payload)
                    .receive("ok", (response) => {
        button.outerHTML = response.button
        this.listen_to(button.dataset.event, podcastChannel)
      })
                    .receive("error", e => console.log(e))
    })
  }
}
export default Podcast