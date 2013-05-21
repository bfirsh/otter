expect = require('chai').expect
OtterBrowser = require '../lib/otter/browser'

describe 'OtterBrowser', ->

  it.skip 'can only open a single window', (done) ->
    browser = new OtterBrowser()
    browser.visit 'about:blank'
    expect(browser.tabs).to.have.length 1
    expect(browser.errors).to.have.length 0

    browser.open url: 'about:blank'
    process.nextTick ->
      expect(browser.tabs).to.have.length 1
      expect(browser.errors).to.have.length 1
      done()

  describe 'getChangedCookieHeaders', ->
    it 'does not return anything if cookies were not changed', ->
      browser = new OtterBrowser()
      browser.setCookiesFromHeader 'foo=bar; Domain=localhost; Path=/', 'localhost'
      expect(browser.getChangedCookieHeaders('localhost')).to.eql []

    it 'returns new headers if none were originally set', ->
      browser = new OtterBrowser()
      browser.setCookie name: 'foo', value: 'bar', domain: 'localhost'
      expect(browser.getChangedCookieHeaders('localhost')).to.eql ['foo=bar; Domain=localhost; Path=/']

    it 'returns updated versions of cookies originally set', ->
      browser = new OtterBrowser()
      browser.setCookiesFromHeader 'foo=bar; Domain=localhost; Path=/', 'localhost'
      browser.setCookie name: 'foo', value: 'baz', domain: 'localhost'
      expect(browser.getChangedCookieHeaders('localhost')).to.eql ['foo=baz; Domain=localhost; Path=/']

    it 'deletes cookies', ->
      browser = new OtterBrowser()
      browser.setCookiesFromHeader 'foo=bar; Domain=localhost; Path=/', 'localhost'
      browser.deleteCookie name: 'foo', domain: 'localhost'
      expect(browser.getChangedCookieHeaders('localhost')).to.eql ['foo=deleted; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Domain=localhost; Path=/']

