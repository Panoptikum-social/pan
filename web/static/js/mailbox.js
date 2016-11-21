import Category from "./category"
import Podcast  from "./podcast"
import Episode  from "./episode"
import User     from "./user"

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

    let podcastlikeButton = document.querySelector("[data-type='podcast'][data-event='like']")
    if(current_user_id != "" && podcastlikeButton != null) {
      let podcast_id = podcastlikeButton.getAttribute("data-id")
      Podcast.onReady(socket, podcast_id)
    }

    let episodelikeButton = document.querySelector("[data-type='episode'][data-event='like']")
    if(current_user_id != "" && episodelikeButton != null) {
      let episode_id = episodelikeButton.getAttribute("data-id")
      Episode.onReady(socket, episode_id)
    }

    let userlikeButton = document.querySelector("[data-type='user'][data-event='like']")
    if(current_user_id != "" && userlikeButton != null) {
      let user_id = userlikeButton.getAttribute("data-id")
      User.onReady(socket, user_id)
    }
  },


  onReady(socket, user_id){
    let mailboxChannel = socket.channel("mailboxes:" + user_id)

    mailboxChannel.join()
      .receive("ok",    resp => console.log("joined mailbox:" + user_id, resp))
      .receive("error", resp => console.log("join of mailbox:"  + user_id + " failed", reason))
  },
}

export default Mailbox