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

    Array.from(document.querySelectorAll("[data-type='category']")).forEach(button => {
      let event = button.dataset.event
      this.listen_to(event, categoryChannel)

      categoryChannel.on(event, (response) =>{
        var button = document.querySelector("[data-type='category']" +
                                            "[data-event='" + event + "']")
        if (response.user_id == window.currentUserID){
          button.outerHTML = response.button
          this.listen_to(event, categoryChannel)
        }
        $('.top-right').notify({type: response.type,
                                message: { html: "<i>" + response.user_name + ":</i> &nbsp;" +
                                                 response.content } }).show()
      })
    })
  },


  listen_to(event, categoryChannel) {
    var button = document.querySelector("[data-type='category']" +
                                        "[data-event='" + event + "']")
    button.addEventListener("click", e => {
      let payload = {category_id: button.dataset.id,
                     action: button.dataset.action}

      categoryChannel.push(button.dataset.event, payload)
                    .receive("error", e => console.log(e))
    })
  }
}

export default Category