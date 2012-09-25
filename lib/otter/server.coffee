express = require 'express'
fs = require 'fs'
path = require 'path'
renderer = require './renderer'

exports.createApp = (options) ->
  app = express()

  app.get '/*', (req, res, next) ->
    fullPath = path.join(options.path, req.url)
    fs.stat fullPath, (err, stats) ->
      # If a static file exists at this path, serve that.
      if stats?.isFile()
        res.sendfile fullPath
      else
        # If a magic flag exists, just output index.html.
        if req.get('X-Otter-No-Render')
          res.sendfile path.join(options.path, 'index.html')
        # If there is no magic flag, pass on the page to the 
        # browser with a magic flag.
        # (Note: this sucks. We need to modify zombiejs so we can just pass
        # it the source of a page, and what URL it's supposed to be.)
        else
          renderer.render
            url: options.baseUrl + req.url
            success: (browser) ->
              res.send browser.document.outerHTML

  return app

exports.start = (options) ->
  options.baseUrl = 'http://127.0.0.1:' + options.port
  app = exports.createApp options
  app.listen options.port
  return app


