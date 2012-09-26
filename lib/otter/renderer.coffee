Browser = require 'zombie'

exports.controller = (options) ->
  (req, res, next) ->
    browser = new Browser
      loadCSS: false
      headers:
        "X-Otter-No-Render": "true"
    browser.visit options.baseUrl + req.url, (err, browser) ->
      if err
        console.log err
      if browser.error
        console.log browser.errors
      res.send browser.document.outerHTML


