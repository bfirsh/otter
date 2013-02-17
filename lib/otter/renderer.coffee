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
      # If there are errors, we have to assume the page has been half-rendered, so just 
      # pass through as a failure
      return next(err) if err

      browser.injectWindowOtter()
      res.send browser.document.outerHTML
      browser.destroy()


