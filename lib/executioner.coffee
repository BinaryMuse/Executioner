ChildProcess = require 'child_process'
Events = require 'events'

exports.ProcessDefinition = class ProcessDefinition
  constructor: (@name, @command, @workingDir) ->
    @terminate = null
    @restart = null
    @logStdout = null
    @logStderr = null

exports.ProcessHistory = class ProcessHistory
  constructor: (@controller) ->
    @log = []
    @events = []
    @stdoutLog = []
    @stderrLog = []

    @controller.on 'start', @handleStart
    @controller.on 'stdout', @handleStdout
    @controller.on 'stderr', @handleStderr
    @controller.on 'stop', @handleStop

  handleStart: (pid) =>
    data =
      event: 'start'
      time: new Date().getTime()
      data:
        pid: pid
    @events.push data

  handleStdout: (data) =>
    @stdoutLog.push data

  handleStderr: (data) =>
    @stderrLog.push data

  handleStop: (code) =>
    data =
      event: 'stop'
      time: new Date().getTime()
      data:
        code: code
    @events.push data

exports.ProcessController = class ProcessController extends Events.EventEmitter
  constructor: (@definition) ->
    @process = null
    @history = new ProcessHistory this
    commandParts = @definition.command.split ' '
    @processCommand = commandParts.shift()
    @processArguments = commandParts

  start: ->
    unless @process?
      @process = ChildProcess.spawn @processCommand, @processArguments, cwd: @definition.workingDir
      @process.stdout.setEncoding 'utf8'
      @process.stderr.setEncoding 'utf8'
      @emit 'start', @process.pid
      @process.stdout.on 'data', (data) =>
        @handleStdout data
      @process.stderr.on 'data', (data) =>
        @handleStderr data
      @process.on 'exit', (code) =>
        @handleExit code
        @process = null

  stop: (signal = 'SIGINT') ->
    if @process?
      @process.kill(signal)

  restart: ->
    this.stop()
    this.start()

  sendInput: (input) ->
    # send to stdin

  handleStdout: (data) ->
    @emit 'stdout', data

  handleStderr: (data) ->
    @emit 'stderr', data

  handleExit: (code) ->
    @emit 'stop', code

