expect = require('chai').expect
express = require 'express'
supertest = require 'supertest'
renderer = require '../lib/otter/renderer'
helpers = require './helpers'

describe 'renderer.controller', ->
  src = app = zombieServer = null
  site = 'http://127.0.0.1:35920'

  # Set up server that zombie can talk to
  before (done) ->
    zombieApp = express()
    zombieApp.all '/script.js', (req, res) ->
      res.send "document.title = 'true'"
    zombieApp.all '/jquery.js', (req, res) ->
      res.sendfile "#{__dirname}/scripts/jquery-1.8.2.js"
    zombieApp.all '/true', (req, res) ->

      res.send 'true'
    zombieApp.all '/static', (req, res) ->
      res.send """<!doctype html><html>
      <head><title>false</title></head>
      <body>
        <script>document.title = "true"</script>
      </body></html>"""
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
      app.get '/', renderer.controller site: site

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

      it 'adds window.otter to the document', (done) ->
        supertest(app)
          .get('/')
          .expect(200)
          .end (err, res) ->
            expect(res.text).to.contain 'window.otter='
            done()

    it 'escapes a closing script tag in window.otter', (done) ->
      src = """
      <body><script>window.otter.cache.test = "<"+"/script>"</script></body>
      """
      supertest(app)
        .get('/')
        .expect(200)
        .end (err, res) ->
          expect(res.text).to.contain '"test":"<\\/script>"'
          done()

    it 'loads the script when a <script> tag points to a local script', (done) ->
      src = """
      <head><title>false</title></head>
      <body><script src="/script.js"></script></body>
      """
      supertest(app).get('/').end (err, res) ->
        expect(res.text).to.contain '<title>true</title>'
        done()

    it 'does not load the script when a <script> points to an external script', (done) ->
      src = """
      <body><script src="http://code.jquery.com/jquery-1.8.2.min.js"></script>'
      <script>if (window.jQuery) document.title = 'true'</script></body>
      """
      supertest(app)
        .get('/')
        .expect(500)
        .end (err, res) -> done(err)

    it 'does not make a request when an XMLHttpRequest is made to an external site', (done) ->
      src = """
      <head><title>false</title></head>
      <body>
        <script src="/jquery.js"></script>
        <script>
          $.get('http://www.example.com/true', function(res) {
            document.title = res
          })
        </script>
      </body>
      """
      supertest(app).get('/').end (err, res) ->
        expect(res.text).to.contain '<title>false</title>'
        done()

    it.skip 'loads the page when an iframe points to a local page', (done) ->
      src = """
      <head><title>false</title></head>
      <body>
        <iframe src="/static"></iframe>
        <script>
          var frame = document.getElementsByTagName("iframe")[0];
          frame.onload = function() {
            document.title = frame.contentDocument.title;
          }
        </script>
      </body>
      """
      supertest(app).get('/').end (err, res) ->
        expect(res.text).to.contain '<title>true</title>'
        done()

    it.skip 'does not load the page when an iframe points to an external page', (done) ->
      src = """
      <body>
        <iframe src="http://www.example.com/static"></iframe>
        <script>
          var frame = document.getElementsByTagName("iframe")[0];
        </script>
      </body>
      """
      supertest(app)
        .get('/')
        .expect(500)
        .end (err, res) -> done(err)

    it 'generates a redirect when window.location is assigned to an external URL', (done) ->
      src = """
      <body>
        <script>
          window.location = "http://www.google.com"
        </script>
      </body>
      """
      supertest(app).get('/').end (err, res) ->
        expect(res.statusCode).to.equal 302
        expect(res.headers['location']).to.equal 'http://www.google.com/'
        done()

    it 'generates a redirect when window.location is assigned to an external URL', (done) ->
      src = """
      <body>
        <script>
          window.location = "/internal"
        </script>
      </body>
      """
      supertest(app).get('/').end (err, res) ->
        expect(res.statusCode).to.equal 302
        expect(res.headers['location']).to.equal '/internal'
        done()

    it 'responds with a 500 if there is an error in the page', (done) ->
      src = """<body><script>ERRORRR</script></body>"""
      supertest(app)
        .get('/')
        .expect(500)
        .end (err, res) -> done(err)

    it 'passes on any cookies in the request to zombie', (done) ->
      src = """
      <head><title></title></head>
      <body>
        <script>
          document.title = document.cookie;
        </script>
      </body>
      """
      supertest(app)
        .get('/')
        .set('cookie', 'foo=bar')
        .end (err, res) ->
          expect(res.text).to.contain '<title>foo=bar</title>'
          done()

    it 'passes on any cookies in the request to zombie', (done) ->
      src = """
      <body>
        <script>
          document.cookie = "foo=bar"
        </script>
      </body>
      """
      supertest(app)
        .get('/')
        .end (err, res) ->
          expect(res.headers['set-cookie']).to.match /^foo=bar/
          done()

  context 'when renderer.controller has "code.jquery.com" in allowedHosts', ->
    beforeEach ->
      app = express()
      app.get '/', renderer.controller site: site, allowedHosts: ['code.jquery.com']

    it 'loads the script when a <script> tag points at a script on code.jquery.com', (done) ->
      src = """
      <head><title>false</title></head>
      <body><script src="http://code.jquery.com/jquery-1.8.2.min.js"></script>'
      <script>if (window.jQuery) document.title = 'true'</script></body>
      """
      supertest(app).get('/').end (err, res) ->
        expect(res.text).to.contain '<title>true</title>'
        done()




