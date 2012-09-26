expect = require('chai').expect
express = require 'express'
request = require 'supertest'
renderer = require '../lib/otter/renderer'

describe 'renderer.controller', ->
  src = zombieServer = app = null
  baseUrl = 'http://127.0.0.1:35920'

  # Set up server that zombie can talk to
  before (done) ->
    zombieApp = express()
    zombieApp.all '/*', (req, res) ->
      res.send src
    zombieServer = zombieApp.listen 35920, ->
      done()

  after ->
    zombieServer.close()

  # Set up app for testing controller
  beforeEach ->
    app = express()

  context 'when the server is serving a basic HTML page', ->
    beforeEach ->
      src = '<!doctype html><html><body>hello</body></html>'
      app.get '/', renderer.controller baseUrl: baseUrl

    it 'renders basic HTML page without changing anything', (done) ->
      request(app)
        .get('/')
        .expect(200)
        .end (err, res) ->
          expect(res.text).to.contain '<body>hello</body>'
          done()






