let Notification = {
  popup(response) {
    var message;
    if(typeof response.user_name == 'undefined'){
      message = response.content
    } else {
      message = "<i>" + response.user_name + ":</i> &nbsp;" + response.content
    }

    if(window.lastMessage != message){
      $.notify({message: message},
               {type: response.type,
                spacing: -5})
      window.lastMessage = message
    }
  }
}

export default Notification