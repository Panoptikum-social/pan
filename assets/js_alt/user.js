import Notification from "./notification"

let User = {
  onReady(socket, user_id){
    let userChannel = socket.channel("users:" + user_id)

    userChannel.join()
      .receive("ok", response => {
        console.log("joined user:" + user_id, response)
      })
      .receive("error", response => {
        console.log("join of user:" + user_id + " failed", reason)
      })

    userChannel.on("notification", (response) => Notification.popup(response) )

    Array.from(document.querySelectorAll("[data-type='user']")).forEach(button => {
      this.listen_to(button.dataset.event, userChannel)
    })
  },


  listen_to(event, userChannel) {
    var button = document.querySelector("[data-type='user']" +
                                        "[data-event='" + event + "']")
    button.addEventListener("click", e => {
      let payload = {user_id: button.dataset.id, action: button.dataset.action}

      userChannel.push(button.dataset.event, payload)
                 .receive("ok", (response) => {
        button.outerHTML = response.button
        this.listen_to(button.dataset.event, userChannel)
      })
          .receive("error", e => console.log(e))
    })
  }
}

export default User