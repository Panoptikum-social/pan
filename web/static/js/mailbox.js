let Mailbox = {
  init(socket){
    socket.connect()
    this.onReady(socket)
  },

  onReady(socket){
    let mailboxChannel = socket.channel("mailboxes:" + window.currentUserID)

    mailboxChannel.join()
      .receive("ok",    resp => console.log("joined the mailbox channel", resp))
      .receive("error", resp => console.log("join failed", reason))

    mailboxChannel.on("like", (resp) =>{
      $('.top-right').notify({
        message: {
          html: "User <b>" + resp.enjoyer + "</b> " + resp.action + "d the podcast <b>" + resp.podcast + "</b>"
        }
      }).show();
    })


    let podcastLink = document.querySelector("[data-type='podcast']")
    let podcastID = podcastLink.getAttribute("href").split("/").slice(-1)[0]
    let action = podcastLink.getAttribute("data-action")

    podcastLink.addEventListener("click", e => {
      let payload = {podcast_id: podcastID,
                     action: action}
      mailboxChannel.push("like", payload)
                    .receive("error", e => console.log(e))
    })
  }
}

export default Mailbox