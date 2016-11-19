import Podcast from "./podcast"

let Mailbox = {
  init(socket){
    let user_id = window.currentUserID

    if(user_id != "") {
      socket.connect()
      this.onReady(socket, user_id)
    }

    let likeButton = document.querySelector("[data-type='podcast'][data-event='like']")
    if(user_id != "" && likeButton != "") {
      let podcast_id = likeButton.getAttribute("data-id")
      Podcast.onReady(socket, podcast_id)
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