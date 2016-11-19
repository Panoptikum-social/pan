import Podcast from "./podcast"
import Episode from "./episode"

let Mailbox = {
  init(socket){
    let user_id = window.currentUserID

    if(user_id != "") {
      socket.connect()
      this.onReady(socket, user_id)
    }

    let podcastlikeButton = document.querySelector("[data-type='podcast'][data-event='like']")
    if(user_id != "" && podcastlikeButton != null) {
      let podcast_id = podcastlikeButton.getAttribute("data-id")
      Podcast.onReady(socket, podcast_id)
    }

    let episodelikeButton = document.querySelector("[data-type='episode'][data-event='like']")
    if(user_id != "" && episodelikeButton != null) {
      let episode_id = episodelikeButton.getAttribute("data-id")
      Episode.onReady(socket, episode_id)
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