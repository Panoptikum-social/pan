import Notification from "./notification"

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

    episodeChannel.on("notification", (response) => Notification.popup(response) )

    Array.from(document.querySelectorAll("[data-type='episode']")).forEach(button => {
      this.listen_to(button.dataset.event, episodeChannel)
    })

    Array.from(document.querySelectorAll("[data-type='chapter']")).forEach(button => {
      this.listen_to_chapter(episodeChannel, button.dataset.id)
    })

    Array.from(document.querySelectorAll("[data-type='persona']")).forEach(button => {
      this.listen_to_proclaim(episodeChannel, button.dataset.personaid)
    })
  },


  listen_to(event, episodeChannel) {
    var button = document.querySelector("[data-type='episode']" +
                                        "[data-event='" + event + "']")
    button.addEventListener("click", e => {
      let payload = {episode_id: button.dataset.id,
                     action: button.dataset.action}

      episodeChannel.push(button.dataset.event, payload)
                    .receive("ok", (response) => {
        button.outerHTML = response.button
        this.listen_to(button.dataset.event, episodeChannel)
      })
                    .receive("error", e => console.log(e))
    })
  },


  listen_to_chapter(episodeChannel, chapter_id) {
    var button = document.querySelector("[data-type='chapter']" +
                                        "[data-event='like-chapter']" +
                                        "[data-id='" + chapter_id + "']")
    button.addEventListener("click", e => {
      let payload = {chapter_id: chapter_id,
                     action: button.dataset.action,
                     persona_id: button.dataset.personaid}

      episodeChannel.push("like-chapter", payload)
                    .receive("ok", (response) => {
        button.outerHTML = response.button
        this.listen_to_chapter(episodeChannel, chapter_id)
      })
                    .receive("error", e => console.log(e))
    })
  },


  listen_to_proclaim(episodeChannel, persona_id) {
    var button = document.querySelector("[data-type='persona']" +
                                        "[data-event='proclaim']" +
                                        "[data-personaid='" + persona_id + "']")
    button.addEventListener("click", e => {
      let payload = {episode_id: button.dataset.id,
                     persona_id: persona_id}

      episodeChannel.push(button.dataset.event, payload)
                    .receive("ok", (response) => {
        button.outerHTML = response.button
        this.listen_to_proclaim(episodeChannel, persona_id)
      })
                    .receive("error", e => console.log(e))

    })
  }
}

export default Episode