Browser = require 'zombie'
URL = require 'url'

module.exports = class OtterBrowser extends Browser
  constructor: (options = {}) ->
    # Attach a magic header to all requests from otter
    options.headers ?= {}
    options.headers["X-Otter-No-Render"] ?= "true"

    @allowedHosts = options.allowedHosts ? []
    # Always allow local requests 
    if options.baseUrl
      @allowedHosts.push(URL.parse(options.baseUrl).host)

    super

    @on 'opened', (window) =>
      # We're opening an iframe, ignore
      return if window.parent != window.top

      # Set up a blank window.otter object
      window.otter =
        isServer: true
        cache: {}

      # Otter browsers can only open a single window.
      if @tabs.length >= 1
        @emit 'error', new Error("Attempt to open a new window, but Otter cannot open multiple windows. href: #{window.location.href}")
        process.nextTick -> window.close()

    # Only open resources if they are in @allowedHosts
    @resources.addHandler (request, next) =>
      parsedUrl = URL.parse(request.url)
      if parsedUrl.host not in @allowedHosts
        err = new Error("Not loading #{parsedUrl.href}: #{parsedUrl.host} not in allowedHosts")
        @emit "error", err
        next(err)
      else
        next()

  # Inject a script into the <head> of the current window that will load the current 
  # value of window.otter when it is reopened in the client.
  injectWindowOtter: =>
    if not @window.otter
      return
    # JSON representation of window.otter
    clientOtter =
      isServer: false,
      cache: @window.otter.cache
    json = JSON.stringify(clientOtter)
    jsonEl = @window.document.createElement('script')
    jsonEl.setAttribute('id', 'otter-data')
    jsonEl.setAttribute('type', 'application/json')
    # No closing tags inside data element
    jsonEl.textContent = json.replace('/', '\\/')
    # short script to parse the window.otter JSON
    scriptEl = @window.document.createElement('script')
    scriptEl.setAttribute('type', 'application/javascript')
    scriptEl.textContent = 'window.otter=JSON.parse(document.getElementById("otter-data").textContent)'
    @window.document.head.insertBefore(jsonEl, @window.document.head.firstChild)
    @window.document.head.insertBefore(scriptEl, jsonEl.nextSibling)



