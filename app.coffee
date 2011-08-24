express = require 'express'
io = require 'socket.io'
executioner = require './lib/executioner'
fs = require 'fs'

app = express.createServer()
io = io.listen app
io.configure ->
  io.set 'transports', ['xhr-polling']
  io.set 'log level', 1

app.configure ->
  app.register '.mustache', require 'stache'
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'mustache'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.compiler(src: __dirname + '/public', enable: ['less'])
  app.use app.router
  app.use express.static(__dirname + '/public')

app.configure 'development', ->
  app.use express.errorHandler(dumpExceptions: true, showStack: true)

app.configure 'production', ->
  app.use express.errorHandler()

app.get '/', (req, res) ->
  res.render 'index',
    locals:
      title: "Testing!"
    partials:
      heading: "<h1>{{title}}</h1>"

definitions = {}
controllers = {}

definitions[1] = new executioner.ProcessDefinition "Random Slow", "node random.js --slow", __dirname
definitions[2] = new executioner.ProcessDefinition "Random Fast", "node random.js --fast", __dirname

controllers[1] = new executioner.ProcessController definitions[1]
controllers[2] = new executioner.ProcessController definitions[2]

bindControllerEvents = (id, controller, socket) ->
  controller.removeAllListeners('start')
  controller.removeAllListeners('stop')
  controller.removeAllListeners('stdout')
  controller.removeAllListeners('stderr')

  controller.on 'start', (pid) ->
    socket.emit 'start', id, pid
  controller.on 'stop', (code) ->
    socket.emit 'stop', id, code
  controller.on 'stdout', (data) ->
    socket.emit 'stdout', id, data
  controller.on 'stderr', (data) ->
    socket.emit 'stderr', id, data

io.sockets.on 'connection', (socket) ->
  socket.emit 'definitions', definitions

  socket.on 'start', (id) ->
    controller = controllers[id]
    bindControllerEvents(id, controller, socket)
    controller.start()
  socket.on 'stop', (id, signal) ->
    controller = controllers[id]
    controller.stop signal
  socket.on 'restart', (id) ->
    controller = controllers[id]
    controller.stop()
    setTimeout (-> controller.start()), 250

#createProcess = (socket) ->
#  definition = new executioner.ProcessDefinition "Test Process", "node test.js", __dirname
#  controller = new executioner.ProcessController definition
#  controllers.push controller

#  controller.on 'start', (pid) ->
#    socket.emit 'start', pid
#  controller.on 'stdout', (data) ->
#    socket.emit 'stdout', data
#  controller.on 'stderr', (data) ->
#    socket.emit 'stderr', data
#  controller.on 'stop', (code) ->
#    socket.emit 'stop', code
#  controller.start()

#io.sockets.on 'connection', (socket) ->
#  socket.on 'start', -> createProcess(this)
#  socket.on 'stop', (pid, signal) ->
#    console.log "Got request to stop process #{pid}"
#    for controller in controllers
#      if controller.process?.pid == pid
#        controller.stop(signal)

app.listen 3000

console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env
