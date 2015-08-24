pty = require 'pty.js'
{execSync} = require 'child_process'

module.exports = (ptyCwd, sh, args, options={}) ->
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

  env = process.env
  try
    cmd = 'test -e /etc/profile && source /etc/profile;test -e ~/.profile && source ~/.profile; node -pe "JSON.stringify(process.env)"'
    external = JSON.parse execSync cmd
    env.PATH = external.PATH
  catch e
  env.HISTCONTROL = 'ignorespace'
  env.PS1 = '\\h:\\W \\u\\$ '

  ptyProcess = pty.fork shell, args,
    cols: cols
    rows: rows
    cwd: ptyCwd
    env: env

  if options.forceTitle
    switch shell.match /\w+(\.exe)?$/
      when 'bash', 'sh'
        ptyProcess.write " trap 'echo -ne \"\\033]2;$BASH_COMMAND\\007\"' DEBUG\r"
      when 'powershell.exe'
        ptyProcess.write """
          function prompt
          {
              $command = Get-History -Count 1
              if ($command) {
                  $host.ui.rawui.WindowTitle = $command
              }
              "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
          }\r
        """
      else
        console.log 'Terminal-Plus: No suitable method found to force shell title.'

  ptyProcess.on 'data', (data) -> emit('terminal-plus:data', data)
  ptyProcess.on 'exit', ->
    emit('terminal-plus:exit')
    callback()
  ptyProcess.on 'close', (data) -> emit('terminal-plus:close', data)

  process.on 'message', ({event, cols, rows, text}={}) ->
    switch event
      when 'resize' then ptyProcess.resize(cols, rows)
      when 'input' then ptyProcess.write(text)
