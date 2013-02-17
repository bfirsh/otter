OtterBrowser = require './browser'

exports.controller = (options) ->
  (req, res, next) ->
    browser = new OtterBrowser
      allowedHosts: options.allowedHosts
      baseUrl: options.baseUrl
    browser.visit options.baseUrl + req.url, (err, browser) ->
      browser.injectWindowOtter()
      res.send browser.document.outerHTML
      browser.destroy()


