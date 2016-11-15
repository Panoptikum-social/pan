let User = {
  init(socket, element){
    if(!element){ return }
    let userID = element.getAttribute("data-user-id")

    socket.connect()
    this.onReady(userID, socket)
  },

  onReady(userID, socket){
    let userChannel = socket.channel("users:" + userID)

    userChannel.join()
      .receive("ok", resp => console.log("joined the user channel", resp))
      .receive("error", resp => console.log("join failed", reason))
  }
}

export default User