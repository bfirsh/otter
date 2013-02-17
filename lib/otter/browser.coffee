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


