Browser = require 'zombie'
URL = require 'url'

patchBrowser = (browser, options = {}) ->
  browser.resources._origMakeRequest = browser.resources._makeRequest
  browser.resources._makeRequest = ({ method, url, data, headers, resource, target }, callback) ->
    parsedUrl = URL.parse url

    if not options.allowedHosts
      options.allowedHosts = []

    # Always allow local requests 
    options.allowedHosts.push(URL.parse(options.baseUrl).host)

    if parsedUrl.host not in options.allowedHosts
      callback new Error("Not loading #{parsedUrl.href}: #{parsedUrl.host} not in allowedHosts")
    else
      @_origMakeRequest 
        method: method, 
        url: url, 
        data: data, 
        headers: headers, 
        resource: resource, 
        target: target
      , callback
    

exports.controller = (options) ->
  (req, res, next) ->
    browser = new Browser
      loadCSS: false
      headers:
        "X-Otter-No-Render": "true"
    patchBrowser(browser, options)
    browser.visit options.baseUrl + req.url, (err, browser) ->
      if err
        console.log err
      if browser.error
        console.log browser.errors
      res.send browser.document.outerHTML


