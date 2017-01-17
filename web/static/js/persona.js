import Notification from "./notification"

let Persona = {
  onReady(socket, persona_id){
    let personaChannel = socket.channel("personas:" + persona_id)

    personaChannel.join()
      .receive("ok", response => {
        console.log("joined persona:" + persona_id, response)
      })
      .receive("error", response => {
        console.log("join of persona:" + persona_id + " failed", reason)
      })

    personaChannel.on("notification", (response) => Notification.popup(response) )

    Array.from(document.querySelectorAll("[data-type='persona']")).forEach(button => {
      this.listen_to(button.dataset.event, personaChannel)
    })
  },


  listen_to(event, personaChannel) {
    var button = document.querySelector("[data-type='persona']" +
                                        "[data-event='" + event + "']")
    button.addEventListener("click", e => {
      let payload = {persona_id: button.dataset.id, action: button.dataset.action}

      personaChannel.push(button.dataset.event, payload)
                    .receive("ok", (response) => {
        button.outerHTML = response.button
        this.listen_to(button.dataset.event, personaChannel)
      })
          .receive("error", e => console.log(e))
    })
  }
}

export default Persona