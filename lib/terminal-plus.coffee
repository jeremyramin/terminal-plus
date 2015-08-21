TerminalPlusView = require './view'
TerminalPlusPanel = require './panel'
Core = require './core'

path = require 'path'
{CompositeDisposable} = require 'atom'

module.exports = TerminalPlus =
  terminalPlusPanel: null
  subscriptions: null

  activate: (state) ->
    @terminalPlusPanel = new TerminalPlusPanel(state.terminalPlusPanelState)
    Core.init()

    # # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    # @subscriptions = new CompositeDisposable
    #
    # # Register command that toggles this view
    # @subscriptions.add atom.commands.add 'atom-workspace', 'terminal-plus:toggle': => @toggle()

  deactivate: ->
    @subscriptions.dispose()
    @terminalPlusPanel.destroy()

  serialize: ->
    terminalPlusPanelState: @terminalPlusPanel.serialize()

  config:
    autoRunCommand:
      type: 'string'
      default: ''
    titleTemplate:
      type: 'string'
      default: "Terminal ({{ bashName }})"
    fontFamily:
      type: 'string'
      default: ''
    fontSize:
      type: 'string'
      default: ''
    colors:
      type: 'object'
      properties:
        normalBlack:
          type: 'color'
          default: '#2e3436'
        normalRed:
          type: 'color'
          default: '#cc0000'
        normalGreen:
          type: 'color'
          default: '#4e9a06'
        normalYellow:
          type: 'color'
          default: '#c4a000'
        normalBlue:
          type: 'color'
          default: '#3465a4'
        normalPurple:
          type: 'color'
          default: '#75507b'
        normalCyan:
          type: 'color'
          default: '#06989a'
        normalWhite:
          type: 'color'
          default: '#d3d7cf'
        brightBlack:
          type: 'color'
          default: '#555753'
        brightRed:
          type: 'color'
          default: '#ef2929'
        brightGreen:
          type: 'color'
          default: '#8ae234'
        brightYellow:
          type: 'color'
          default: '#fce94f'
        brightBlue:
          type: 'color'
          default: '#729fcf'
        brightPurple:
          type: 'color'
          default: '#ad7fa8'
        brightCyan:
          type: 'color'
          default: '#34e2e2'
        brightWhite:
          type: 'color'
          default: '#eeeeec'
        background:
          type: 'color'
          default: '#000000'
        foreground:
          type: 'color'
          default: '#f0f0f0'
    scrollback:
      type: 'integer'
      default: 1000
    cursorBlink:
      type: 'boolean'
      default: true
    shellOverride:
      type: 'string'
      default: ''
    shellArguments:
      type: 'string'
      default: do ({SHELL, HOME}=process.env) ->
        switch path.basename SHELL.toLowerCase()
          when 'bash' then "--init-file #{path.join HOME, '.bash_profile'}"
          when 'zsh'  then ""
          else ''
    'WindowHeight':
      type: 'integer'
      description: 'Maximum height of a console window.'
      default: 300
    'enableWindowAnimations':
      title: 'Enable window animations'
      description: 'Enable window animations.'
      type: 'boolean'
      default: true
    'useAtomIcons':
      title: 'Use Atom icons'
      description: 'Uses only the icons used by the Atom. Otherwise the default terminal icons will be used.'
      type: 'boolean'
      default: true
    'clearCommandInput':
      title: 'Clear command input'
      description: 'Always clear command input when opening terminal panel.'
      type: 'boolean'
      default: true
    'logConsole':
      title: 'Log console'
      description: 'Log console output.'
      type: 'boolean'
      default: false
    'overrideLs':
      title: 'Override ls'
      description: 'Override ls command (if this option is disabled the native version of ls is used)'
      type: 'boolean'
      default: true
    'enableExtendedCommands':
      title: 'Enable extended built-in commands'
      description: 'Enable extended built-in commands (like ls override, cd or echo).'
      type: 'boolean'
      default: true
    'enableUserCommands':
      title: 'Enable user commands'
      description: 'Enable user defined commands from terminal-commands.json file'
      type: 'boolean'
      default: true
    'enableConsoleInteractiveLinks':
      title: 'Enable console interactive links'
      description: 'If this option is disabled or terminal links are not clickable (the file extensions will be coloured only)'
      type: 'boolean'
      default: true
    'enableConsoleInteractiveHints':
      title: 'Enable console interactive hints'
      description: 'Enable terminal tooltips.'
      type: 'boolean'
      default: true
    'enableConsoleLabels':
      title: 'Enable console labels (like %(label:info...), error, warning)'
      description: 'If this option is disabled all labels are removed.'
      type: 'boolean'
      default: true
    'enableConsoleStartupInfo':
      title: 'Enable the console welcome message.'
      description: 'Always display welcome message when the terminal window is opened.'
      type: 'boolean'
      default: true
    'enableConsoleSuggestionsDropdown':
      title: 'Enable the console suggestions list.'
      description: 'Makes the console display the suggested commands list in a dropdown list.'
      type: 'boolean'
      default: true
    'disabledExtendedCommands':
      title: 'Disabled commands:'
      description: 'You can disable any command (it will be used as native).'
      type: 'array'
      default: []
      items:
        type: 'string'
    'moveToCurrentDirOnOpen':
      title: 'Always move to current directory'
      description: 'Always move to currently selected file\'s directory when the console is opened.'
      type: 'boolean'
      default: true
    'moveToCurrentDirOnOpenLS':
      title: 'Always run \"ls\" in active console.'
      description: 'Always run \"ls\" command when the console is opened (slows down terminal a little).'
      type: 'boolean'
      default: false
    'parseSpecialTemplateTokens':
      title: 'Enable the special tokens (like: %(path), %(day) etc.)'
      description: 'If this option is disabled all special tokens are removed.'
      type: 'boolean'
      default: true
    'commandPrompt':
      title: 'The command prompt message.'
      description: 'Set the command prompt message.'
      type: 'string'
      default: '%(dynamic) %(label:badge:text:%(line)) %(^#FF851B)%(hours):%(minutes):%(seconds)%(^) %(^#01FF70)%(hostname)%(^):%(^#DDDDDD)%(^#39CCCC)../%(path:-2)/%(path:-1)%(^)>%(^)'
    'textReplacementCurrentPath':
      title: 'Current working directory replacement'
      description: 'Replacement for the current working directory path at the console output.'
      type: 'string'
      default: '[CWD]'
    'textReplacementCurrentFile':
      title: 'Currently edited file replacement'
      description: 'Replacement for the currently edited file at the console output.'
      type: 'string'
      default: '%(link)%(file)%(endlink)'
    'textReplacementFileAdress':
      title: 'File adress replacement'
      description: 'Replacement for any file adress at the console output.'
      type: 'string'
      default: '%(link)%(file)%(endlink)'
    'statusBarText':
      title: 'Status bar text'
      description: 'Text displayed on the terminal status bar.'
      type: 'string'
      default: '%(dynamic) %(hostname) %(username) %(hours):%(minutes):%(seconds) %(ampm)'
    'XExperimentEnableForceLinking':
      title: 'EXPERIMENTAL: Enable auto links'
      description: 'Warning: This function is experimental, so it can be broken.'
      type: 'boolean'
      default: false
