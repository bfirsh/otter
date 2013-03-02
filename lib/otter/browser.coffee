Browser = require 'zombie'
FS = require 'fs'
Q = require 'q'
Path = require 'path'
URL = require 'url'

module.exports = class OtterBrowser extends Browser
  constructor: (options = {}) ->
    super

    @allowedHosts = options.allowedHosts ? []
    @path = options.path

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
        # Strip @site from start of href
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

    # Zombie doesn't play well with bound functions
    _this = @
    @resources.addHandler (request, next) -> _this._handleRequest(request, next)

  # Intercept all requests Zombie does and do our own processing.
  _handleRequest: (request, next) =>
    parsedUrl = URL.parse(request.url)
    siteHost = URL.parse(@site).host
    # Local request, load straight off the filesystem
    if @path and parsedUrl.host == siteHost
      fullPath = Path.join(@path, parsedUrl.pathname)
      FS.stat fullPath, (err, stats) =>
        if not stats?.isFile()
          fullPath = Path.join(@path, 'index.html')
        FS.readFile fullPath, (err, body) =>
          if err
            next(err)
          else
            next(null, body: body)
    # Only open remote resources if they are in @allowedHosts
    else if parsedUrl.host not in @allowedHosts and parsedUrl.host != siteHost
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



