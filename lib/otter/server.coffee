express = require 'express'
fs = require 'fs'
path = require 'path'
renderer = require './renderer'

exports.createApp = (options) ->
  app = express()
  if options.logging
    app.use express.logger()

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
          renderer.controller(options) req, res, (err) =>
            # If there was an error rendering, we must assume the page was 
            # half-rendered, so let the client render it instead.
            if err
              res.sendfile path.join(options.path, 'index.html')
            else
              next()

  return app

exports.start = (options) ->
  options.site = 'http://127.0.0.1:' + options.port
  app = exports.createApp options
  app.listen options.port
  return app


