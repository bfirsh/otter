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
    requestCookie = req.headers['cookie']
    browser.cookies(hostname).update requestCookie
    # Load URL
    browser.visit req.url, (err, browser) ->
      # If there are errors, we have to assume the page has been half-rendered, so just 
      # pass through as a failure
      return next(err) if err

      browser.injectWindowOtter()

      # Set cookies
      # TODO: only return cookies that have changed, unset cookies which have been
      # removed.
      headers = []
      for cookie in browser.cookies(hostname).all()
        headers.push ['Set-Cookie', cookie.toString()]

      res.writeHead 200, headers
      res.write browser.document.outerHTML
      res.end()

      browser.destroy()


