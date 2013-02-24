server = require './server'
docopt = require 'docopt'
packagejson = require '../../package.json'

doc = """
Otter is an HTTP server that renders your client-side apps with Zombie.js.

Usage: 
  otter [options] <path>
  otter -h | --help
  otter -v | --version

Options:
  -h --help     Show this screen.
  -v --version  Show version.
  -a <hosts>    A comma separated list of hosts to allow connections to.
  -l --logging  Enable logging.
  -p <port>     Port to listen on. [default: 8000]
  -w <num>      Number of workers to spawn. Defaults to number of CPUs.

"""

exports.run = ->
  options = docopt.docopt(doc, version: packagejson.version)
  cluster = server.start 
    port: options['-p']
    path: options['<path>']
    allowedHosts: options['-a'].split(',') if options['-a']
    logging: options['--logging']
    workers: Math.floor(options['-w']) if options['-w']
  if cluster.isMaster
    numberOfWorkers = Object.keys(cluster.workers).length
    console.log "Spawned #{numberOfWorkers} worker#{if numberOfWorkers == 1 then '' else 's'}."
  else
    console.log "Worker listening on port #{options['-p']}."


