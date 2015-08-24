pty = require 'pty.js'
{execSync} = require 'child_process'

module.exports = (ptyCwd, sh, args) ->
  callback = @async()
  if sh
    shell = sh
  else
    if process.platform is 'win32'
      path = require 'path'
      shell = path.resolve(process.env.SystemRoot, 'WindowsPowerShell', 'v1.0', 'powershell.exe')
    else
      shell = process.env.SHELL

  cols = 80
  rows = 30

  try
    cmd = 'test -e /etc/profile && source /etc/profile;test -e ~/.profile && source ~/.profile; node -pe "JSON.stringify(process.env)"'
    env = JSON.parse execSync cmd
  catch e
    env = process.env

  if shell is 'bash' or 'sh'
    env.PS1 = "\\h:\\W \\u\\$ "

  ptyProcess = pty.fork shell, args,
    cols: cols
    rows: rows
    cwd: ptyCwd
    env: env

  ptyProcess.on 'data', (data) -> emit('terminal-plus:data', data)
  ptyProcess.on 'exit', ->
    emit('terminal-plus:exit')
    callback()

  process.on 'message', ({event, cols, rows, text}={}) ->
    switch event
      when 'resize' then ptyProcess.resize(cols, rows)
      when 'input' then ptyProcess.write(text)
