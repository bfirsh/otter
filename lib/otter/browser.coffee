Browser = require 'zombie'

module.exports = class OtterBrowser extends Browser
  constructor: (options = {}) ->
    super

    # Otter browsers can only open a single window.
    @on 'opened', (window) =>
      # We're opening an iframe, ignore
      return if window.parent != window.top

      if @tabs.length >= 1
        @emit 'error', new Error("Attempt to open a new window, but Otter cannot open multiple windows. href: #{window.location.href}")
        process.nextTick -> window.close()

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



