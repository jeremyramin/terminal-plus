{CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

TerminalDisplay = null
Shell = null
InputDialog = null
RenameDialog = null
StatusIcon = null

os = require 'os'

module.exports =
class Terminal extends View
  process: ''
  title: ''
  name: ''
  rowHeight: 20
  colWidth: 9
  prevHeight: null
  currentHeight: null
  parentView: null
  shell: null
  display: null
  opened: false

  @content: ->
    @div class: 'xterm'

  @getFocusedTerminal: ->
    return null unless TerminalDisplay
    return TerminalDisplay.Terminal.focus

  initialize: ({@shellPath, @pwd, @id}) ->
    TerminalDisplay ?= require 'term.js'
    Shell ?= require './shell'
    StatusIcon ?= require './status-icon'

    @subscriptions = new CompositeDisposable()
    @core = require './core'

    @statusIcon = new StatusIcon()
    @statusIcon.initialize(this)
    @registerAnimationSpeed()

    override = (event) ->
      return if event.originalEvent.dataTransfer.getData('terminal-plus') is 'true'
      event.preventDefault()
      event.stopPropagation()

    @on 'mouseup', (event) =>
      if event.which != 3
        text = window.getSelection().toString()
        unless text
          @parentView.focus()
    @on 'dragenter', override
    @on 'dragover', override
    @on 'drop', @recieveItemOrFile
    @on 'focus', @focus

  destroy: ->
    @subscriptions.dispose()
    @shell.destroy() if @shell
    @display.destroy() if @display
    @statusIcon.destroy()

    @core.removeTerminal(this)


  ###
  Section: Setup
  ###

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

    @subscriptions.add atom.config.observe 'terminal-plus.style.fontAntialiasing', (value) =>
      switch value
        when "Antialiased"
          @display.element.style["-webkit-font-smoothing"] = "antialiased"
        when "Default"
          @display.element.style["-webkit-font-smoothing"] = "subpixel-antialiased"
        when "None"
          @display.element.style["-webkit-font-smoothing"] = "none"

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

  displayView: ->
    return false if @opened
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
    return true

  registerAnimationSpeed: ->
    @subscriptions.add atom.config.observe 'terminal-plus.style.animationSpeed',
      (value) =>
        if value == 0
          @animationSpeed = 100
        else
          @animationSpeed = parseFloat(value)
        @css 'transition', "height #{0.25 / @animationSpeed}s linear"


  ###
  Section: External Methods
  ###

  blur: =>
    @blurTerminal()
    super()

  focus: =>
    @recalibrateSize()
    @focusTerminal()
    @core.setActiveTerminal(this)
    super()

  getDisplay: ->
    return @display

  getTitle: ->
    return @title or @process

  getRowHeight: ->
    return @rowHeight

  getColWidth: ->
    return @colWidth

  getId: ->
    return @id

  recalibrateSize: ->
    return unless @display

    {cols, rows} = @getDimensions()
    return unless cols > 0 and rows > 0
    return if @display.rows is rows and @display.cols is cols

    @resize cols, rows
    @display.resize cols, rows

  height: (height) ->
    return super() if not height?

    if height != @currentHeight
      @prevHeight = @currentHeight
      @currentHeight = height
    return super(height)

  clearHeight: ->
    @prevHeight = @height()
    return @css "height", "0"

  getPrevHeight: ->
    return @prevHeight

  input: (data) ->
    @shell.input data

  resize: (cols, rows) ->
    @shell.resize cols, rows

  getCols: ->
    return @display.cols

  getRows: ->
    return @display.rows

  isFocused: ->
    return Terminal.getFocusedTerminal() == @display

  isTabView: ->
    return false unless @parentView
    return @parentView.constructor?.name is "TabView"

  isPanelView: ->
    return false unless @parentView
    return @parentView.constructor?.name is "PanelView"

  setName: (name) ->
    if @name isnt name
      @name = name
      @parentView.updateName(name)

  getName: ->
    return @name

  promptForRename: =>
    RenameDialog ?= require './rename-dialog'
    dialog = new RenameDialog this
    dialog.attach()

  promptForInput: =>
    InputDialog ?= require('./input-dialog')
    dialog = new InputDialog this
    dialog.attach()

  copy: ->
    if @display._selected
      textarea = @display.getCopyTextarea()
      text = @display.grabText(
        @display._selected.x1, @display._selected.x2,
        @display._selected.y1, @display._selected.y2)
    else
      rawText = @display.context.getSelection().toString()
      rawLines = rawText.split(/\r?\n/g)
      lines = rawLines.map (line) ->
        line.replace(/\s/g, " ").trimRight()
      text = lines.join("\n")
    atom.clipboard.write text

  paste: ->
    @input atom.clipboard.read()

  insertSelection: ->
    return unless editor = atom.workspace.getActiveTextEditor()
    runCommand = atom.config.get('terminal-plus.toggles.runInsertedText')

    if selection = editor.getSelectedText()
      @display.stopScrolling()
      @input "#{selection}#{if runCommand then os.EOL else ''}"
    else if cursor = editor.getCursorBufferPosition()
      line = editor.lineTextForBufferRow(cursor.row)
      @display.stopScrolling()
      @input "#{line}#{if runCommand then os.EOL else ''}"
      editor.moveDown(1)

  disableAnimation: ->
    @css 'transition', ""

  enableAnimation: ->
    @css 'transition', "height #{0.25 / @animationSpeed}s linear"

  getParentView: ->
    return @parentView

  setParentView: (view) ->
    @parentView = view
    return this

  isAnimating: ->
    return @parentView.isAnimating()

  open: ->
    @parentView.open()

  toggle: ->
    @parentView.toggle()

  toggleFullscreen: ->
    @parentView.toggleFullscreen()

  toggleFocus: ->
    @parentView.toggleFocus()

  getStatusIcon: ->
    return @statusIcon

  hideIcon: ->
    @statusIcon.hide()

  showIcon: ->
    @statusIcon.show()


  ###
  Section: Helper Methods
  ###

  blurTerminal: =>
    return unless @display

    @display.blur()
    @display.element.blur()

  focusTerminal: =>
    return unless @display

    @display.focus()
    if @display._textarea
      @display._textarea.focus()
    else
      @display.element.focus()

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
