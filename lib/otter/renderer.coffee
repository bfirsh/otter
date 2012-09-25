Browser = require 'zombie'

exports.render = (options) ->
  browser = new Browser
    loadCSS: false
    headers:
      "X-Otter-No-Render": "true"
  browser.visit options.url, (err, browser) ->
    if err
      console.log err
    if browser.error
      console.log browser.errors
    options.success browser


