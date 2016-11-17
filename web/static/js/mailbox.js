import Podcast from "./podcast"

let Mailbox = {
  init(socket){
    let user_id = window.currentUserID

    if(user_id != "") {
      socket.connect()
      this.onReady(socket, user_id)
    }

    let podcastButton = document.querySelector("[data-type='podcast']")
    if(user_id != "" && podcastButton != "") {
      Podcast.onReady(socket, podcastButton)
    }
  },


  onReady(socket, user_id){
    let mailboxChannel = socket.channel("mailboxes:" + user_id)

    mailboxChannel.join()
      .receive("ok",    resp => console.log("joined the mailbox channel", resp))
      .receive("error", resp => console.log("join of mailbox channel failed", reason))
  },
}

export default Mailbox