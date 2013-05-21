Browser = require 'zombie'
FS = require 'fs'
Q = require 'q'
Path = require 'path'
Cookie = require("tough-cookie").Cookie
URL = require 'url'

module.exports = class OtterBrowser extends Browser
  constructor: (options = {}) ->
    # Attach a magic header to all requests from otter
    options.headers ?= {}
    options.headers["X-Otter"] ?= "true"

    super

    @allowedHosts = options.allowedHosts ? []
    # Always allow local requests
    if @site
      @allowedHosts.push(URL.parse(@site).host)
    @path = options.path

    @on 'opened', (window) =>
      # We're opening an iframe, ignore
      return if window.parent != window.top

      # Otter browsers can only open a single window.
      # TODO: fix this for new version of zombie
      #if window.name != "otter"
      #  @emit 'error', new Error("Attempt to open a new window, but Otter cannot open multiple windows. href: #{window.location.href}")
      #  process.nextTick -> window.close()
      #  return

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

  # A way of setting cookies that remembers which were originally set.
  # Does not work with paths yet.
  setCookiesFromHeader: (header, domain) =>
    if not domain
      domain = URL.parse(@site).hostname
    @cookies.update header, domain
    @_prevCookies = (cookie for cookie in @cookies)

  # If cookies were set with @setCookiesFromHeader, returns a list of
  # Set-Cookie headers to set the cookies which have changed since
  getChangedCookieHeaders: (domain) =>
    if not @_prevCookies
      @_prevCookies = []

    if not domain
      domain = URL.parse(@site).hostname

    headers = []
    
    # Generate mapping of key to cookie string
    prevCookieStrings = {}
    for cookie in @_prevCookies
      if cookie.domain == domain
        prevCookieStrings[cookie.key] = cookie.toString()

    newCookieStrings = []
    for cookie in @cookies.select(domain: domain)
      newCookieStrings[cookie.key] = cookie.toString()

    # Add cookies which have been set or changed
    for key, cookie of newCookieStrings
      if prevCookieStrings[key] != cookie
        headers.push cookie

    # Delete cookies which have been removed
    for key, cookie of prevCookieStrings
      if not newCookieStrings[key]
        cookie = Cookie.parse(cookie)
        cookie.value = "deleted"
        cookie.expires = "Thu, 01 Jan 1970 00:00:00 GMT"
        headers.push cookie.toString()

    return headers


