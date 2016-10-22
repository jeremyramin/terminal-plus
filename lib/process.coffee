pty = require 'pty.js'
path = require 'path'
fs = require 'fs'
_ = require 'underscore'
child = require 'child_process'

systemLanguage = do ->
  language = "en_US.UTF-8"
  if process.platform is 'darwin'
    try
      command = 'plutil -convert json -o - ~/Library/Preferences/.GlobalPreferences.plist'
      language = "#{JSON.parse(child.execSync(command).toString()).AppleLocale}.UTF-8"
  return language

filteredEnvironment = do ->
  env = _.omit process.env, 'ATOM_HOME', 'ATOM_SHELL_INTERNAL_RUN_AS_NODE', 'GOOGLE_API_KEY', 'NODE_ENV', 'NODE_PATH', 'userAgent', 'taskPath'
  env.LANG ?= systemLanguage
  env.TERM_PROGRAM = 'Terminal-Plus'
  return env

module.exports = (pwd, shell, args, options={}) ->
  callback = @async()

  if /zsh|bash/.test(shell) and args.indexOf('--login') == -1
    args.unshift '--login'

  ptyProcess = pty.fork shell, args,
    cwd: pwd,
    env: filteredEnvironment,
    name: 'xterm-256color'

  title = shell = path.basename shell

  emitTitle = _.throttle ->
    emit('terminal-plus:title', ptyProcess.process)
  , 500, true

  ptyProcess.on 'data', (data) ->
    emit('terminal-plus:data', data)
    emitTitle()

  ptyProcess.on 'exit', ->
    emit('terminal-plus:exit')
    callback()

  process.on 'message', ({event, cols, rows, text}={}) ->
    switch event
      when 'resize' then ptyProcess.resize(cols, rows)
      when 'input' then ptyProcess.write(text)
