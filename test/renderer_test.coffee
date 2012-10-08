expect = require('chai').expect
express = require 'express'
supertest = require 'supertest'
renderer = require '../lib/otter/renderer'
helpers = require './helpers'

describe 'renderer.controller', ->
  src = app = zombieServer = null
  baseUrl = 'http://127.0.0.1:35920'

  # Set up server that zombie can talk to
  before (done) ->
    zombieApp = express()
    zombieApp.all '/script.js', (req, res) ->
      res.send "document.title = 'true'"
    zombieApp.all '/*', (req, res) ->
      res.send src
    zombieServer = zombieApp.listen 35920, ->
      done()

  after ->
    zombieServer.close()

  context 'when renderer.controller has no options', ->
    beforeEach ->
      # Set up app for testing controller
      app = express()
      app.get '/', renderer.controller baseUrl: baseUrl

    context 'when the server is serving a basic HTML page', ->
      beforeEach ->
        src = '<!doctype html><html><body>hello</body></html>'

      it 'renders basic HTML page without changing anything', (done) ->
        supertest(app)
          .get('/')
          .expect(200)
          .end (err, res) ->
            expect(res.text).to.contain '<body>hello</body>'
            done()

    context 'when a <script> tag points to a local script', ->
      beforeEach ->
        src = """
        <head><title>false</title></head>
        <body><script src="/script.js"></script></body>
        """

      it 'loads the script', (done) ->
        supertest(app).get('/').end (err, res) ->
          expect(res.text).to.contain '<title>true</title>'
          done()

    context 'when a <script> points to an external script', ->
      beforeEach ->
        src = """
        <head><title>false</title></head>
        <body><script src="http://code.jquery.com/jquery-1.8.2.min.js"></script>'
        <script>if (window.jQuery) document.title = 'true'</script></body>
        """

      it 'does not load the script', (done) ->
        supertest(app).get('/').end (err, res) ->
          expect(res.text).to.contain '<title>false</title>'
          done()

    context 'when an iframe points to a local page', ->
      it 'loads the page'

    context 'when an iframe points to an external page', ->
      it 'does not load the page'

    context 'when window.location is assigned', ->
      it 'throws an error'

  context 'when renderer.controller has "code.jquery.com" in allowedHosts', ->
    beforeEach ->
      app = express()
      app.get '/', renderer.controller baseUrl: baseUrl, allowedHosts: ['code.jquery.com']
    context 'when a <script> tag points at a script on code.jquery.com', ->
      beforeEach ->
        src = """
        <head><title>false</title></head>
        <body><script src="http://code.jquery.com/jquery-1.8.2.min.js"></script>'
        <script>if (window.jQuery) document.title = 'true'</script></body>
        """

      it 'does loads the script', (done) ->
        supertest(app).get('/').end (err, res) ->
          expect(res.text).to.contain '<title>true</title>'
          done()


