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
        autoClose:
          title: 'Close Terminal on Exit'
          description: 'Should the terminal close if the shell exits?'
          type: 'boolean'
          default: false
        cursorBlink:
          title: 'Cursor Blink'
          description: 'Should the cursor blink when the terminal is active?'
          type: 'boolean'
          default: true
        runInsertedText:
          title: 'Run Inserted Text'
          description: 'Run text inserted via `terminal-plus:insert-text` as a command? **This will append an end-of-line character to input.**'
          type: 'boolean'
          default: true
    core:
      type: 'object'
      order: 2
      properties:
        autoRunCommand:
          title: 'Auto Run Command'
          description: 'Command to run on terminal initialization.'
          type: 'string'
          default: ''
        mapTerminalsTo:
          title: 'Map Terminals To'
          description: 'Map terminals to each file or folder. Default is no action or mapping at all. **Restart required.**'
          type: 'string'
          default: 'None'
          enum: ['None', 'File', 'Folder']
        mapTerminalsToAutoOpen:
          title: 'Auto Open a New Terminal (For Terminal Mapping)'
          description: 'Should a new terminal be opened for new items? **Note:** This works in conjunction with `Map Terminals To` above.'
          type: 'boolean'
          default: false
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
          description: 'Override the terminal\'s default font family. **You must use a [monospaced font](https://en.wikipedia.org/wiki/List_of_typefaces#Monospace)!**'
          type: 'string'
          default: ''
        fontSize:
          title: 'Font Size'
          description: 'Override the terminal\'s default font size.'
          type: 'string'
          default: ''
        defaultPanelHeight:
          title: 'Default Panel Height'
          description: 'Default height of a terminal panel. **You may enter a value in px, em, or %.**'
          type: 'string'
          default: '300px'
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
            'dracula'
          ]
    ansiColors:
      type: 'object'
      order: 4
      properties:
        normal:
          type: 'object'
          order: 1
          properties:
            black:
              title: 'Black'
              description: 'Black color used for terminal ANSI color set.'
              type: 'color'
              default: '#000000'
            red:
              title: 'Red'
              description: 'Red color used for terminal ANSI color set.'
              type: 'color'
              default: '#CD0000'
            green:
              title: 'Green'
              description: 'Green color used for terminal ANSI color set.'
              type: 'color'
              default: '#00CD00'
            yellow:
              title: 'Yellow'
              description: 'Yellow color used for terminal ANSI color set.'
              type: 'color'
              default: '#CDCD00'
            blue:
              title: 'Blue'
              description: 'Blue color used for terminal ANSI color set.'
              type: 'color'
              default: '#0000CD'
            magenta:
              title: 'Magenta'
              description: 'Magenta color used for terminal ANSI color set.'
              type: 'color'
              default: '#CD00CD'
            cyan:
              title: 'Cyan'
              description: 'Cyan color used for terminal ANSI color set.'
              type: 'color'
              default: '#00CDCD'
            white:
              title: 'White'
              description: 'White color used for terminal ANSI color set.'
              type: 'color'
              default: '#E5E5E5'
        zBright:
          type: 'object'
          order: 2
          properties:
            brightBlack:
              title: 'Bright Black'
              description: 'Bright black color used for terminal ANSI color set.'
              type: 'color'
              default: '#7F7F7F'
            brightRed:
              title: 'Bright Red'
              description: 'Bright red color used for terminal ANSI color set.'
              type: 'color'
              default: '#FF0000'
            brightGreen:
              title: 'Bright Green'
              description: 'Bright green color used for terminal ANSI color set.'
              type: 'color'
              default: '#00FF00'
            brightYellow:
              title: 'Bright Yellow'
              description: 'Bright yellow color used for terminal ANSI color set.'
              type: 'color'
              default: '#FFFF00'
            brightBlue:
              title: 'Bright Blue'
              description: 'Bright blue color used for terminal ANSI color set.'
              type: 'color'
              default: '#0000FF'
            brightMagenta:
              title: 'Bright Magenta'
              description: 'Bright magenta color used for terminal ANSI color set.'
              type: 'color'
              default: '#FF00FF'
            brightCyan:
              title: 'Bright Cyan'
              description: 'Bright cyan color used for terminal ANSI color set.'
              type: 'color'
              default: '#00FFFF'
            brightWhite:
              title: 'Bright White'
              description: 'Bright white color used for terminal ANSI color set.'
              type: 'color'
              default: '#FFFFFF'
    iconColors:
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
