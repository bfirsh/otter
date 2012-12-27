server = require './server'
docopt = require 'docopt'

doc = """
Otter is an HTTP server that renders your client-side apps with Zombie.js.

Usage: 
  otter [options] <path>
  otter -h | --help
  otter -v | --version

Options:
  -h --help     Show this screen.
  -v --version  Show version.
  -p <port>     Port to listen on. [default: 8000]
  -a <hosts>    A comma separated list of hosts to allow connections to.

"""

exports.run = ->
  options = docopt.docopt(doc, version: '0.1.0')
  server.start 
    port: options['-p']
    path: options['<path>']
    allowedHosts: options['-a']?.split(',')
  console.log "Server started on port #{options['-p']}."


