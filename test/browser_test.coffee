expect = require('chai').expect
OtterBrowser = require '../lib/otter/browser'

describe 'OtterBrowser', ->

  it 'can only open a single window', (done) ->
    browser = new OtterBrowser()
    browser.visit 'about:blank'
    expect(browser.tabs).to.have.length 1
    expect(browser.errors).to.have.length 0

    browser.open url: 'about:blank'
    process.nextTick ->
      expect(browser.tabs).to.have.length 1
      expect(browser.errors).to.have.length 1
      done()


