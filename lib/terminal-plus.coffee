TerminalPlusView = require './view'
TerminalPlusPanel = require './panel'

path = require 'path'
{CompositeDisposable} = require 'atom'

module.exports = TerminalPlus =
  terminalPlusPanel: null
  subscriptions: null

  activate: (state) ->
    @terminalPlusPanel = new TerminalPlusPanel(state.terminalPlusPanelState)
    @subscriptions = new CompositeDisposable

    # # Register command that toggles this view
    # @subscriptions.add atom.commands.add 'atom-workspace', 'terminal-plus:toggle': => @toggle()

  deactivate: ->
    @subscriptions.dispose()
    @terminalPlusPanel.destroy()

  serialize: ->
    terminalPlusPanelState: @terminalPlusPanel.serialize()

  config:
    style:
      title: 'Style'
      type: 'object'
      properties:
        theme:
          title: 'Theme'
          description: 'Select a theme for the terminal.'
          type: 'string'
          default: 'standard'
          enum: [
            'standard',
            'inverse',
            'grass',
            'homebrew',
            'man-page',
            'novel',
            'ocean',
            'pro',
            'red',
            'red-sands',
            'silver-aerogel',
            'solid-colors',
          ]
        fontFamily:
          title: 'Font Family'
          description: 'Override the editor\'s default font family.'
          type: 'string'
          default: ''
        fontSize:
          title: 'Font Size'
          description: 'Override the editor\'s default font size.'
          type: 'integer'
          default: 0
          minimum: 0
        maxPanelHeight:
          title: 'Maximum Panel Height'
          description: 'Maximum height of a terminal panel.'
          type: 'integer'
          default: 300
          minimum: 50
        toggles:
          type: 'object'
          properties:
            cursorBlink:
              title: 'Cursor Blink'
              description: 'Should the cursor blink when the terminal is active?'
              type: 'boolean'
              default: true
            windowAnimations:
              title: 'Window Animations'
              description: 'Do you want the panel to transition open and closed?'
              type: 'boolean'
              default: true
    core:
      title: 'Style'
      type: 'object'
      properties:
        autoRunCommand:
          title: 'Auto Run Command'
          description: 'Command to run on terminal initialization.'
          type: 'string'
          default: ''
        scrollback:
          title: 'Scroll Back'
          description: 'How many lines of history should be kept?'
          type: 'integer'
          default: 1000
        shellOverride:
          title: 'Shell Override'
          description: 'Override the default shell instance to launch.'
          type: 'string'
          default: ''
        shellArguments:
          title: 'Shell Arguments'
          description: 'Specify some arguments to use when launching the shell.'
          type: 'string'
          default: do ({SHELL, HOME}=process.env) ->
            switch path.basename SHELL.toLowerCase()
              when 'bash' then "--init-file #{path.join HOME, '.bash_profile'}"
              when 'zsh'  then ''
              else ''
