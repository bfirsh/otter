Browser = require 'zombie'
Q = require 'q'
URL = require 'url'

module.exports = class OtterBrowser extends Browser
  constructor: (options = {}) ->
    # Attach a magic header to all requests from otter
    options.headers ?= {}
    options.headers["X-Otter-No-Render"] ?= "true"

    super

    @allowedHosts = options.allowedHosts ? []
    # Always allow local requests 
    if @site
      @allowedHosts.push(URL.parse(@site).host)

    @on 'opened', (window) =>
      # We're opening an iframe, ignore
      return if window.parent != window.top

      # Otter browsers can only open a single window.
      if window.name != "otter"
        @emit 'error', new Error("Attempt to open a new window, but Otter cannot open multiple windows. href: #{window.location.href}")
        process.nextTick -> window.close()
        return

      # If we've already loaded a page, we're navigating to another page. Otter doesn't 
      # let you do this, so trigger a "navigate" event and close down the browser.
      #
      # Ideally we'd just stop the page loading from this point, but this part of 
      # Zombie is really hard to extend (all stuck inside createHistory). At some 
      # point we should patch Zombie to make this better.
      if @tabs.length != 0
        href = window.location.href
        if @site and href.substring(0, @site.length) == @site
          href = href.substring(@site.length)
        @emit "navigate", href
        process.nextTick -> window.close()
        return

      # This is the first page being loaded
      # Set up a blank window.otter object
      window.otter =
        isServer: true
        cache: {}


    # Only open resources if they are in @allowedHosts
    @resources.addHandler (request, next) =>
      parsedUrl = URL.parse(request.url)
      if parsedUrl.host not in @allowedHosts
        err = new Error("Not loading #{parsedUrl.href}: #{parsedUrl.host} not in allowedHosts")
        @emit "error", err
        next(err)
      else
        next()

  # Loads a document from the specified URL. This is the entry point to using an Otter 
  # browser - other methods are currently unsupported.
  #
  # This is a copied and pasted version of visit from Zombie, merely setting the tab 
  # name to "otter". TODO: submit patch to Zombie to allow setting this.
  visit: (url, options, callback)->
    if typeof options == "function" && !callback
      [callback, options] = [options, null]

    deferred = Q.defer()
    resetOptions = @withOptions(options)
    if site = @site
      site = "http://#{site}" unless /^(https?:|file:)/i.test(site)
      url = URL.resolve(site, URL.parse(URL.format(url)))

    if @window
      @tabs.close(@window)
    @tabs.open(url: url, referer: @referer, name: "otter")
    @wait options, (error)=>
      resetOptions()
      if error
        deferred.reject(error)
      else
        deferred.resolve()
      if callback
        callback error, this, @statusCode, @errors
    return deferred.promise unless callback

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



