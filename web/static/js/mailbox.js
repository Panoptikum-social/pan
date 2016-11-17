let Mailbox = {
  init(socket){
    socket.connect()
    this.onReady(socket)
  },

  onReady(socket){
    let mailboxChannel = socket.channel("mailboxes:" + window.currentUserID)
    let podcastButton = document.querySelector("[data-type='podcast']")

    mailboxChannel.join()
      .receive("ok",    resp => console.log("joined the mailbox channel", resp))
      .receive("error", resp => console.log("join failed", reason))

    mailboxChannel.on("like", (resp) =>{
      podcastButton.outerHTML = resp.button

      //reregistering the event handler, because we have a new button
      podcastButton = document.querySelector("[data-type='podcast']")
      this.registerButton(mailboxChannel, podcastButton)

      $('.top-right').notify({
        type: resp.type,
        message: { html: resp.content }
      }).show();
    })

    this.registerButton(mailboxChannel, podcastButton)
  },

  registerButton(mailboxChannel, podcastButton){
    podcastButton.addEventListener("click", e => {
      let payload = {podcast_id: podcastButton.getAttribute("data-id"),
                     action: podcastButton.getAttribute("data-action")}

      mailboxChannel.push("like", payload)
                    .receive("error", e => console.log(e))
    })
  }
}

export default Mailbox