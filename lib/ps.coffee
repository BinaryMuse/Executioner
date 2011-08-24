child_proc = require 'child_process'

module.exports = (callback) ->
  buffer = ''
  ps = child_proc.spawn 'ps', ['ax']
  ps.stdout.on 'data', (data) ->
    buffer += data
  ps.on 'exit', (code) ->
    callback buffer

