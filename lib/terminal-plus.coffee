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
          description: 'Override the terminal\'s font family. **You must use a [monospaced font](https://en.wikipedia.org/wiki/List_of_typefaces#Monospace)!**'
          type: 'string'
          default: 'monospace'
        fontSize:
          title: 'Font Size'
          description: 'Override the terminal\'s default font size.'
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
    termColors:
      title: 'Terminal Colors'
      description: 'Set termnal colors.'
      order: 4
      type: 'object'
      properties:
        black:
          title: 'Dark Black'
          description: 'Dark black color used for terminal.'
          type: 'color'
          default: '#2e3436'
        red:
          title: 'Dark Red'
          description: 'Dark red color used for terminal.'
          type: 'color'
          default: '#cc0000'
        green:
          title: 'Dark Green'
          description: 'Dark green color used for terminal.'
          type: 'color'
          default: '#4e9a06'
        yellow:
          title: 'Dark Yellow'
          description: 'Dark black color used for terminal.'
          type: 'color'
          default: '#c4a000'
        blue:
          title: 'Dark Blue'
          description: 'Dark black color used for terminal.'
          type: 'color'
          default: '#3465a4'
        magenta:
          title: 'Dark Magenta'
          description: 'Dark black color used for terminal.'
          type: 'color'
          default: '#75507b'
        cyan:
          title: 'Dark Cyan'
          description: 'Dark black color used for terminal.'
          type: 'color'
          default: '#06989a'
        white:
          title: 'Dark White'
          description: 'Dark black color used for terminal.'
          type: 'color'
          default: '#d3d7cf'
        brightBlack:
          title: 'Bright Black'
          description: 'Dark black color used for terminal.'
          type: 'color'
          default: '#555753'
        brightRed:
          title: 'Bright Red'
          description: 'Bright red color used for terminal.'
          type: 'color'
          default: '#ef2929'
        brightGreen:
          title: 'Bright Green'
          description: 'Bright green color used for terminal.'
          type: 'color'
          default: '#8ae234'
        brightYellow:
          title: 'Bright Yellow'
          description: 'Bright yellow color used for terminal.'
          type: 'color'
          default: '#fce94f'
        brightBlue:
          title: 'Bright Blue'
          description: 'Bright blue color used for terminal.'
          type: 'color'
          default: '#729fcf'
        brightMagenta:
          title: 'Bright Magenta'
          description: 'Bright magenta color used for terminal.'
          type: 'color'
          default: '#ad7fa8'
        brightCyan:
          title: 'Bright Cyan'
          description: 'Bright cyan color used for terminal.'
          type: 'color'
          default: '#34e2e2'
        brightWhite:
          title: 'Bright White'
          description: 'Bright white color used for terminal.'
          type: 'color'
          default: '#eeeeec'
        bgColor:
          title: 'Background color'
          description: 'Background color used for terminal.'
          type: 'color'
          default: '#2e3436'
        fgColor:
          title: 'Foreground color'
          description: 'Foreground (text) color used for terminal.'
          type: 'color'
          default: '#d3d7cf'
    colors:
      type: 'object'
      order: 5
      properties:
        red:
          title: 'Status Icon Red'
          description: 'Red color used for status icon.'
          type: 'color'
          default: 'red'
        orange:
          title: 'Status Icon Orange'
          description: 'Orange color used for status icon.'
          type: 'color'
          default: 'orange'
        yellow:
          title: 'Status Icon Yellow'
          description: 'Yellow color used for status icon.'
          type: 'color'
          default: 'yellow'
        green:
          title: 'Status Icon Green'
          description: 'Green color used for status icon.'
          type: 'color'
          default: 'green'
        blue:
          title: 'Status Icon Blue'
          description: 'Blue color used for status icon.'
          type: 'color'
          default: 'blue'
        purple:
          title: 'Status Icon Purple'
          description: 'Purple color used for status icon.'
          type: 'color'
          default: 'purple'
        pink:
          title: 'Status Icon Pink'
          description: 'Pink color used for status icon.'
          type: 'color'
          default: 'hotpink'
        cyan:
          title: 'Status Icon Cyan'
          description: 'Cyan color used for status icon.'
          type: 'color'
          default: 'cyan'
        magenta:
          title: 'Status Icon Magenta'
          description: 'Magenta color used for status icon.'
          type: 'color'
          default: 'magenta'
