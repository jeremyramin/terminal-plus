pty = require 'pty.js'
path = require 'path'
fs = require 'fs'

module.exports = (ptyCwd, shell, args, options={}) ->
  callback = @async()
  run = shell
  title = shell = path.basename shell

  if fs.existsSync '/usr/bin/login'
    run = "login"
    args.unshift shell
    args.unshift process.env.USER
    args.unshift "-qf"
  else
    args.unshift '--login'

  cols = 80
  rows = 40

  ptyProcess = pty.fork run, args,
    cols: cols
    rows: rows
    cwd: ptyCwd

  ptyProcess.on 'data', (data) ->
    emit('terminal-plus:data', data)

  ptyProcess.on 'data', ->
    newTitle = ptyProcess.process
    if newTitle is shell
      emit('terminal-plus:clear-title')
    else unless title is newTitle
      emit('terminal-plus:title', newTitle)
    title = newTitle

  ptyProcess.on 'exit', ->
    emit('terminal-plus:exit')
    callback()

  ptyProcess.on 'close', (data) ->
    emit('terminal-plus:close', data)

  process.on 'message', ({event, cols, rows, text}={}) ->
    switch event
      when 'resize' then ptyProcess.resize(cols, rows)
      when 'input' then ptyProcess.write(text)
