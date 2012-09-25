server = require './server'
docopt = require 'docopt'

doc = """
Run your client-side apps server-side.

Usage: 
  otter [options] <path>
  otter -h | --help
  otter -v | --version

Options:
  -h --help     Show this screen.
  -v --version  Show version.
  -p <port>     Port to listen on. [default: 8000]

"""

exports.run = ->
  options = docopt.docopt(doc, version: '0.1.0')
  server.start 
    port: options['-p']
    path: options['<path>']
  console.log "Server started on port #{options['-p']}."


