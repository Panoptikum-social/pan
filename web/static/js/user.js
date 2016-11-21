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

    Array.from(document.querySelectorAll("[data-type='user']")).forEach(button => {
      let event = button.dataset.event
      this.listen_to(event, userChannel)

      userChannel.on(event, (response) =>{
        var button = document.querySelector("[data-type='user']" +
                                            "[data-event='" + event + "']")
        button.outerHTML = response.button
        this.listen_to(event, userChannel)
        $('.top-right').notify({type: response.type,
                                message: { html: "<i>" + response.user_name + ":</i> &nbsp;" +
                                                 response.content } }).show()
      })
    })
  },


  listen_to(event, userChannel) {
    var button = document.querySelector("[data-type='user']" +
                                        "[data-event='" + event + "']")
    button.addEventListener("click", e => {
      let payload = {user_id: button.dataset.id,
                     action: button.dataset.action}

      userChannel.push(button.dataset.event, payload)
                    .receive("error", e => console.log(e))
    })
  }
}

export default User