OtterBrowser = require './browser'
fs = require 'fs'
path = require 'path'
URL = require 'url'

exports.createBrowser = (options = {}) ->
  browser = new OtterBrowser
    headers:
      "X-Otter-No-Render": "true"
  browser.on 'opened', (window) ->
    window.otter =
      isServer: true
      cache: {}
  browser.resources.addHandler (request, next) ->
    allowedHosts = []
    if options.allowedHosts
      allowedHosts = allowedHosts.concat(options.allowedHosts)
    # Always allow local requests 
    allowedHosts.push(URL.parse(options.baseUrl).host)

    parsedUrl = URL.parse(request.url)
    if parsedUrl.host not in allowedHosts
      err = new Error("Not loading #{parsedUrl.href}: #{parsedUrl.host} not in allowedHosts")
      console.error(err)
      next(err)
    else
      next()

  return browser

exports.controller = (options) ->
  (req, res, next) ->
    browser = exports.createBrowser(options)
    browser.visit options.baseUrl + req.url, (err, browser) ->
      if err
        console.log err
      if browser.error
        console.log browser.errors
      browser.injectWindowOtter()
      res.send browser.document.outerHTML
      browser.destroy()


