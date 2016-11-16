let User = {
  init(socket, element){
    if(!element){ return }
    let userID = element.getAttribute("data-user-id")

    socket.connect()
    this.onReady(userID, socket)
  },


  onReady(userID, socket){
    let userChannel = socket.channel("users:" + userID)
    let podcastLink = document.getElementById("podcast-link")
    let podcastID = podcastLink.href.split("/").slice(-1)[0]
    userChannel.join()
      .receive("ok",    resp => console.log("joined the user channel", resp))
      .receive("error", resp => console.log("join failed", reason))

    userChannel.on("like", (resp) =>{
      $('.top-right').notify({
        message: {
          html: "User <b>" + resp.enjoyer + "</b> liked the podcast <b>" + resp.podcast + "</b>"
        }
      }).show();
    })

    podcastLink.addEventListener("click", e => {
      let payload = {enjoyer_id: userID, podcast_id: podcastID}
      userChannel.push("like", payload)
                 .receive("error", e => console.log(e))
    })
  }
}

export default User