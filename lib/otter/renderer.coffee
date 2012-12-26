Browser = require 'zombie'
fs = require 'fs'
path = require 'path'
URL = require 'url'

createBrowser = (options = {}) ->
  browser = new Browser
    headers:
      "X-Otter-No-Render": "true"
  browser.resources.addHandler (request, next) ->
    if not options.allowedHosts
      options.allowedHosts = []
    # Always allow local requests 
    options.allowedHosts.push(URL.parse(options.baseUrl).host)

    parsedUrl = URL.parse(request.url)
    if parsedUrl.host not in options.allowedHosts
      next(new Error("Not loading #{parsedUrl.href}: #{parsedUrl.host} not in allowedHosts"))
    else
      next()

  return browser

exports.controller = (options) ->
  (req, res, next) ->
    browser = createBrowser(options)
    browser.visit options.baseUrl + req.url, (err, browser) ->
      if err
        console.log err
      if browser.error
        console.log browser.errors
      res.send browser.document.outerHTML


