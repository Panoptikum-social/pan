let Notification = {
  popup(response) {
    var message = { html: "<i>" + response.user_name + ":</i> &nbsp;" + response.content }
    if(window.lastMessage != message.html){
      $('.top-right').notify({type: response.type, message: message }).show()
      window.lastMessage = message.html
    }
  }
}

export default Notification