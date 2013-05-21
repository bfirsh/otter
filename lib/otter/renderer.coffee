OtterBrowser = require './browser'
URL = require 'url'

exports.controller = (options) ->
  hostname = URL.parse(options.site).hostname
  (req, res, next) ->
    browser = new OtterBrowser
      allowedHosts: options.allowedHosts
      path: options.path
      site: options.site
    # Handle redirects
    browser.on "navigate", (url) ->
      console.log url
      res.redirect(url)
      browser.destroy()

    # Set cookies
    if req.headers['cookie']
      browser.setCookiesFromHeader req.headers['cookie'], hostname

    # Load URL
    browser.visit req.url, (err) ->
      # If there are errors, we have to assume the page has been half-rendered, so just 
      # pass through as a failure
      return next(err) if err

      browser.injectWindowOtter()

      # Generate cookies
      headers = (['Set-Cookie', cookie] for cookie in browser.getChangedCookieHeaders())
      res.writeHead 200, headers
      res.write browser.document.outerHTML
      res.end()

      browser.destroy()


