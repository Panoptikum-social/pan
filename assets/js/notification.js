let Notification = {
  mounted() {
    function notifyMe(message) {
      if (window.Notification.permission === "granted") {
        new window.Notification(message);
      }
      else if (Notification.permission !== "denied") {
        window.Notification.requestPermission().then(function (permission) {
          if (permission === "granted") {
            new window.Notification(message);
          }
        });
      }
    }
    this.handleEvent("notification", function({content}) { 
      notifyMe(content); 
    });
  }
};

export { Notification };
