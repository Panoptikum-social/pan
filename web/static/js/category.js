import Notification from "./notification"

let Category = {
  onReady(socket, category_id){
    let categoryChannel = socket.channel("categories:" + category_id)

    categoryChannel.join()
      .receive("ok", response => {
        console.log("joined category:" + category_id, response)
      })
      .receive("error", response => {
        console.log("join of category:" + category_id + " failed", reason)
      })

    categoryChannel.on("notification", (response) => Notification.popup(response) )

    Array.from(document.querySelectorAll("[data-type='category']")).forEach(button => {
      this.listen_to(button.dataset.event, categoryChannel)
    })
  },


  listen_to(event, categoryChannel) {
    var button = document.querySelector("[data-type='category']" +
                                        "[data-event='" + event + "']")
    button.addEventListener("click", e => {
      let payload = {category_id: button.dataset.id, action: button.dataset.action}

      categoryChannel.push(button.dataset.event, payload)
                    .receive("ok", (response) => {
        button.outerHTML = response.button
        this.listen_to(button.dataset.event, episodeChannel)
      })
                    .receive("error", e => console.log(e))
    })
  }
}

export default Category