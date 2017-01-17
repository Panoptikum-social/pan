import Notification from "./notification"
import Category     from "./category"
import Podcast      from "./podcast"
import Episode      from "./episode"
import User         from "./user"
window.lastMessage = "unset"

let Mailbox = {
  init(socket){
    let current_user_id = window.currentUserID

    if(current_user_id != "") {
      socket.connect()
      this.onReady(socket, current_user_id)
    }

    let categorylikeButton = document.querySelector("[data-type='category'][data-event='like']")
    if(current_user_id != "" && categorylikeButton != null) {
      let category_id = categorylikeButton.getAttribute("data-id")
      Category.onReady(socket, category_id)
    }

    let podcastlikeButtons = document.querySelectorAll("[data-type='podcast'][data-event='like']")
    if(current_user_id != "" && podcastlikeButtons != []) {
      Array.from(podcastlikeButtons).forEach(button => {
        let podcast_id = button.getAttribute("data-id")
        Podcast.onReady(socket, podcast_id)
      })
    }

    let episodeElement = document.querySelector("[data-type='episode']")
    if(episodeElement != null) {
      let episode_id = episodeElement.getAttribute("data-id")
      Episode.onReady(socket, episode_id)
    }

    let userlikeButton = document.querySelector("[data-type='user'][data-event='like']")
    if(current_user_id != "" && userlikeButton != null) {
      let user_id = userlikeButton.getAttribute("data-id")
      User.onReady(socket, user_id)
    }

    let personalikeButton = document.querySelector("[data-type='persona'][data-event='like']")
    if(current_user_id != "" && personalikeButton != null) {
      let persona_id = userlikeButton.getAttribute("data-id")
      Persona.onReady(socket, persona_id)
    }
  },


  onReady(socket, user_id){
    let mailboxChannel = socket.channel("mailboxes:" + user_id)

    mailboxChannel.join()
      .receive("ok",    resp => console.log("joined mailbox:" + user_id, resp))
      .receive("error", resp => console.log("join of mailbox:"  + user_id + " failed", reason))

    mailboxChannel.on("notification", (response) => Notification.popup(response) )
  }
}

export default Mailbox