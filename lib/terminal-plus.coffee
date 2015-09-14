module.exports =
  statusBar: null

  activate: ->
    @statusBar = new (require './status-bar')()

  deactivate: ->
    @statusBar.destroy()

  config:
    toggles:
      type: 'object'
      order: 1
      properties:
        cursorBlink:
          title: 'Cursor Blink'
          description: 'Should the cursor blink when the terminal is active?'
          type: 'boolean'
          default: true
        autoClose:
          title: 'Close Terminal on Exit'
          description: 'Should the terminal close if the shell exits?'
          type: 'boolean'
          default: false
    core:
      type: 'object'
      order: 2
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
        shell:
          title: 'Shell Override'
          description: 'Override the default shell instance to launch.'
          type: 'string'
          default: do ->
            if process.platform is 'win32'
              path = require 'path'
              path.resolve(process.env.SystemRoot, 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe')
            else
              process.env.SHELL
        shellArguments:
          title: 'Shell Arguments'
          description: 'Specify some arguments to use when launching the shell.'
          type: 'string'
          default: ''
        workingDirectory:
          title: 'Working Directory'
          description: 'Which directory should be the present working directory when a new terminal is made?'
          type: 'string'
          default: 'Project'
          enum: ['Home', 'Project', 'Active File']
    style:
      type: 'object'
      order: 3
      properties:
        animationSpeed:
          title: 'Animation Speed'
          description: 'How fast should the window animate?'
          type: 'number'
          default: '1'
          minimum: '0'
          maximum: '100'
        fontFamily:
          title: 'Font Family'
          description: 'Override the editor\'s default font family. **You must use a [monospaced font](https://en.wikipedia.org/wiki/List_of_typefaces#Monospace)!**'
          type: 'string'
          default: 'monospace'
        fontSize:
          title: 'Font Size'
          description: 'Override the editor\'s default font size.'
          type: 'integer'
          default: do -> atom.config.get('editor.fontSize')
          minimum: 1
          maximum: 100
        defaultPanelHeight:
          title: 'Default Panel Height'
          description: 'Default height of a terminal panel.'
          type: 'integer'
          default: 300
          minimum: 0
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
    colors:
      type: 'object'
      order: 4
      properties:
        red:
          title: 'Red'
          description: 'Red color used for status icon.'
          type: 'color'
          default: 'red'
        orange:
          title: 'Orange'
          description: 'Orange color used for status icon.'
          type: 'color'
          default: 'orange'
        yellow:
          title: 'Yellow'
          description: 'Yellow color used for status icon.'
          type: 'color'
          default: 'yellow'
        green:
          title: 'Green'
          description: 'Green color used for status icon.'
          type: 'color'
          default: 'green'
        blue:
          title: 'Blue'
          description: 'Blue color used for status icon.'
          type: 'color'
          default: 'blue'
        purple:
          title: 'Purple'
          description: 'Purple color used for status icon.'
          type: 'color'
          default: 'purple'
        pink:
          title: 'Pink'
          description: 'Pink color used for status icon.'
          type: 'color'
          default: 'hotpink'
        cyan:
          title: 'Cyan'
          description: 'Cyan color used for status icon.'
          type: 'color'
          default: 'cyan'
        magenta:
          title: 'Magenta'
          description: 'Magenta color used for status icon.'
          type: 'color'
          default: 'magenta'
