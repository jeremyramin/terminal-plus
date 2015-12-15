{CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

TerminalDisplay = null
Shell = null

os = require 'os'

module.exports =
class Terminal extends View
  process: ''
  title: ''
  rowHeight: 20
  colWidth: 9
  shell: null
  display: null
  opened: false

  @content: ->
    @div class: 'xterm'

  @getFocusedTerminal: ->
    return null unless TerminalDisplay
    return TerminalDisplay.Terminal.focus

  initialize: ({@shellPath, @pwd}) ->
    TerminalDisplay ?= require 'term.js'
    Shell ?= require './shell'
    @subscriptions = new CompositeDisposable

    override = (event) ->
      return if event.originalEvent.dataTransfer.getData('terminal-plus') is 'true'
      event.preventDefault()
      event.stopPropagation()

    @on 'mouseup', (event) =>
      if event.which != 3
        text = window.getSelection().toString()
        unless text
          @focus()
    @on 'dragenter', override
    @on 'dragover', override
    @on 'drop', @recieveItemOrFile
    @on 'focus', @focus

  recieveItemOrFile: (event) =>
    event.preventDefault()
    event.stopPropagation()
    {dataTransfer} = event.originalEvent

    if dataTransfer.getData('atom-event') is 'true'
      filePath = dataTransfer.getData('text/plain')
      @input "#{filePath} " if filePath
    else if filePath = dataTransfer.getData('initialPath')
      @input "#{filePath} "
    else if dataTransfer.files.length > 0
      for file in dataTransfer.files
        @input "#{file.path} "

  displayView: ->
    return @focus() if @opened
    @opened = true

    {cols, rows} = @getDimensions()
    @shell = new Shell {@pwd, @shellPath}

    @display = new TerminalDisplay {
      cursorBlink : false
      scrollback : atom.config.get 'terminal-plus.core.scrollback'
      cols, rows
    }

    @attachListeners()
    @display.open @element

  attachListeners: ->
    @shell.on "terminal-plus:data", (data) =>
      @display.write data

    @shell.on "terminal-plus:exit", =>
      @destroy() if atom.config.get('terminal-plus.toggles.autoClose')

    @display.end = => @destroy()

    @display.on "data", (data) =>
      @shell.input data

    @shell.on "terminal-plus:title", (title) =>
      @process = title
    @display.on "title", (title) =>
      @title = title

    @display.once "open", =>
      @applyStyle()
      @recalibrateSize()

      autoRunCommand = atom.config.get('terminal-plus.core.autoRunCommand')
      @input "#{autoRunCommand}#{os.EOL}" if autoRunCommand

  destroy: ->
    @subscriptions.dispose()
    @shell.destroy() if @shell
    @display.destroy() if @display

  applyStyle: ->
    config = atom.config.get 'terminal-plus'

    @addClass config.style.theme
    @addClass 'cursor-blink' if config.toggles.cursorBlink

    editorFont = atom.config.get('editor.fontFamily')
    defaultFont = "Menlo, Consolas, 'DejaVu Sans Mono', monospace"
    overrideFont = config.style.fontFamily
    @display.element.style.fontFamily = overrideFont or editorFont or defaultFont

    @subscriptions.add atom.config.onDidChange 'editor.fontFamily', (event) =>
      editorFont = event.newValue
      @display.element.style.fontFamily = overrideFont or editorFont or defaultFont
    @subscriptions.add atom.config.onDidChange 'terminal-plus.style.fontFamily', (event) =>
      overrideFont = event.newValue
      @display.element.style.fontFamily = overrideFont or editorFont or defaultFont

    editorFontSize = atom.config.get('editor.fontSize')
    overrideFontSize = config.style.fontSize
    @display.element.style.fontSize = "#{overrideFontSize or editorFontSize}px"

    @subscriptions.add atom.config.onDidChange 'editor.fontSize', (event) =>
      editorFontSize = event.newValue
      @display.element.style.fontSize = "#{overrideFontSize or editorFontSize}px"
      @recalibrateSize()
    @subscriptions.add atom.config.onDidChange 'terminal-plus.style.fontSize', (event) =>
      overrideFontSize = event.newValue
      @display.element.style.fontSize = "#{overrideFontSize or editorFontSize}px"
      @recalibrateSize()

    # first 8 colors i.e. 'dark' colors
    @display.colors[0..7] = [
      config.ansiColors.normal.black.toHexString()
      config.ansiColors.normal.red.toHexString()
      config.ansiColors.normal.green.toHexString()
      config.ansiColors.normal.yellow.toHexString()
      config.ansiColors.normal.blue.toHexString()
      config.ansiColors.normal.magenta.toHexString()
      config.ansiColors.normal.cyan.toHexString()
      config.ansiColors.normal.white.toHexString()
    ]
    # 'bright' colors
    @display.colors[8..15] = [
      config.ansiColors.zBright.brightBlack.toHexString()
      config.ansiColors.zBright.brightRed.toHexString()
      config.ansiColors.zBright.brightGreen.toHexString()
      config.ansiColors.zBright.brightYellow.toHexString()
      config.ansiColors.zBright.brightBlue.toHexString()
      config.ansiColors.zBright.brightMagenta.toHexString()
      config.ansiColors.zBright.brightCyan.toHexString()
      config.ansiColors.zBright.brightWhite.toHexString()
    ]

  focus: =>
    @recalibrateSize()
    @focusTerminal()
    super()

  blur: =>
    @blurTerminal()
    super()

  focusTerminal: =>
    return unless @display

    @display.focus()
    if @display._textarea
      @display._textarea.focus()
    else
      @display.element.focus()

  blurTerminal: =>
    return unless @display

    @display.blur()
    @display.element.blur()

  recalibrateSize: ->
    return unless @display

    {cols, rows} = @getDimensions()
    return unless cols > 0 and rows > 0
    return if @display.rows is rows and @display.cols is cols

    @resize cols, rows
    @display.resize cols, rows

  getDimensions: ->
    fakeRow = $("<div><span>&nbsp;</span></div>")

    if @display
      @find('.terminal').append fakeRow
      fakeCol = fakeRow.children().first()[0].getBoundingClientRect()
      cols = Math.floor @width() / (fakeCol.width or 9)
      rows = Math.floor @height() / (fakeCol.height or 20)
      @rowHeight = fakeCol.height
      @colWidth = fakeCol.width
      fakeRow.remove()
    else
      cols = Math.floor @width() / 9
      rows = Math.floor @height() / 20

    {cols, rows}

  input: (data) ->
    @display.stopScrolling()
    @shell.input data

  resize: (cols, rows) ->
    @shell.resize cols, rows

  stopScrolling: ->
    @display.stopScrolling()

  getDisplay: ->
    return @display

  getTitle: ->
    return @title or @process

  getRowHeight: ->
    return @rowHeight

  getColWidth: ->
    return @colWidth

  getParentView: ->
    return @parentView

  setParentView: (view) ->
    @parentView = view
    return this
