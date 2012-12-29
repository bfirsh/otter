Browser = require 'zombie'
fs = require 'fs'
path = require 'path'
URL = require 'url'

exports.createBrowser = (options = {}) ->
  browser = new Browser
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

insertWindowOtter = (window) ->
  doc = window.document
  if not window.otter
    return
  # JSON representation of window.otter
  clientOtter =
    isServer: false,
    cache: window.otter.cache
  json = JSON.stringify(clientOtter)
  jsonEl = doc.createElement('script')
  jsonEl.setAttribute('id', 'otter-data')
  jsonEl.setAttribute('type', 'application/json')
  # No closing tags inside data element
  jsonEl.textContent = json.replace('/', '\\/')
  # short script to parse the window.otter JSON
  scriptEl = doc.createElement('script')
  scriptEl.setAttribute('type', 'application/javascript')
  scriptEl.textContent = 'window.otter=JSON.parse(document.getElementById("otter-data").textContent)'
  doc.head.insertBefore(jsonEl, doc.head.firstChild)
  doc.head.insertBefore(scriptEl, jsonEl.nextSibling)

exports.controller = (options) ->
  (req, res, next) ->
    browser = exports.createBrowser(options)
    browser.visit options.baseUrl + req.url, (err, browser) ->
      if err
        console.log err
      if browser.error
        console.log browser.errors
      insertWindowOtter(browser.window)
      res.send browser.document.outerHTML
      browser.destroy()


