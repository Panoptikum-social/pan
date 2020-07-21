import tinyToast from "./tiny-toast"

let Notification = {
  popup(response) {
    var message;
    if(typeof response.user_name == 'undefined'){
      message = response.content
    } else {
      message = "<i>" + response.user_name + ":</i> &nbsp;" + response.content
    }

    if(window.lastMessage != message){
      tinyToast.show(message, response.type).hide(50000)
      window.lastMessage = message
    }
  }
}

export default Notification