let PodloveSubscribeButton = {
  mounted() {
    this.pushEventTo(this.el, "read-config", {}, (resp, ref) => { 
      window['podcastData'] = resp;
      const scripttag = document.createElement('script');
      scripttag.async = true;
      scripttag.src = '/subscribe-button/javascripts/app.js';
 
      scripttag.setAttribute('class', 'podlove-subscribe-button')
      scripttag.setAttribute('data-language', 'en')
      scripttag.setAttribute('data-size', 'medium')
      scripttag.setAttribute('data-json-data', 'podcastData')
      scripttag.setAttribute('data-color', '#ED5565')
      scripttag.setAttribute('data-format', 'rectangle')
      scripttag.setAttribute('data-style', 'filled')

      this.el.appendChild(scripttag);
     })
  }
};

export { PodloveSubscribeButton };
