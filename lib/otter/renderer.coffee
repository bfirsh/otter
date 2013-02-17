OtterBrowser = require './browser'

exports.controller = (options) ->
  (req, res, next) ->
    browser = new OtterBrowser
      allowedHosts: options.allowedHosts
      site: options.site
    browser.on "navigate", (url) ->
      console.log url
      res.redirect(url)
      browser.destroy()
    browser.visit req.url, (err, browser) ->
      browser.injectWindowOtter()
      res.send browser.document.outerHTML
      browser.destroy()


