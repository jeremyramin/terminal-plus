path = require 'path'
os = require 'os'
fs = require 'fs-plus'
keypather = do require 'keypather'

{Task} = require 'atom'
{$, View} = require 'atom-space-pen-views'

Pty = require.resolve './process'
Terminal = require 'term.js'

lastOpenedView = null

last = (str)-> str[str.length-1]

renderTemplate = (template, data)->
  vars = Object.keys data
  vars.reduce (_template, key)->
    _template.split(///\{\{\s*#{key}\s*\}\}///)
      .join data[key]
  , template.toString()

module.exports =
class TerminalPlusView extends View
  opened: false
  xtermColors:[
    # dark:
    '#000000', # black
    '#cd0000', # red3
    '#00cd00', # green3
    '#cdcd00', # yellow3
    '#0000ee', # blue2
    '#cd00cd', # magenta3
    '#00cdcd', # cyan3
    '#e5e5e5', # gray90
    # bright:
    '#7f7f7f', # gray50
    '#ff0000', # red
    '#00ff00', # green
    '#ffff00', # yellow
    '#5c5cff', # rgb:5c/5c/ff
    '#ff00ff', # magenta
    '#00ffff', # cyan
    '#ffffff'  # white
  ]
  @content: () ->
    @div tabIndex: -1, class: 'terminal-plus terminal-plus-view', outlet: 'terminalPlusView', =>
      @div class: 'panel-divider', style: 'cursor:row-resize; width:100%; height: 5px;', outlet: 'panelDivider'
      @div class: 'panel-heading btn-toolbar', outlet:'consoleToolbarHeading', =>
        # @div class: 'btn-group', outlet:'consoleToolbar', =>
        @button outlet: 'closeBtn', click: 'close', class: 'btn icon icon-chevron-down inline-block-tight right', =>
          @span 'close'
        @button outlet: 'exitBtn', class: 'btn icon icon-x inline-block-tight right', click: 'destroy', =>
          @span 'exit'
      @div class: 'xterm', outlet: 'xterm'

  constructor: (@opts={})->
    if opts.shellOverride
      opts.shell = opts.shellOverride
    else
      opts.shell = process.env.SHELL or 'bash'
    opts.shellArguments or= ''
    editorPath = keypather.get atom, 'workspace.getEditorViews[0].getEditor().getPath()'
    opts.cwd = opts.cwd or atom.project.getPaths()[0] or editorPath or process.env.HOME
    super

  forkPtyProcess: (sh, args=[]) ->
    path = atom.project.getPaths()[0] ? '~'
    forceTitle = atom.config.get('terminal-plus.toggles.forceTitle')
    Task.once Pty, fs.absolute(path), sh, args, forceTitle: forceTitle

  displayTerminal: () ->
    {cols, rows} = @getDimensions()
    {cwd, shell, shellArguments, shellOverride, runCommand, cursorBlink, scrollback} = @opts
    args = shellArguments.split(/\s+/g).filter (arg)-> arg
    @ptyProcess = @forkPtyProcess shellOverride, args

    @terminal = term = new Terminal {
      useStyle: false
      screenKeys: false
      colors: @xtermColors
      cursorBlink, scrollback, cols, rows
    }

    @setupListeners()

    @terminal.open @find('.xterm').get(0)
    @input "#{runCommand}#{os.EOL}" if runCommand
    term.focus()

    @applyStyle()
    @attachEvents()
    @resizeToPanel()

  setupListeners: () ->
    @ptyProcess.once 'terminal-plus:data', (data) =>
      @ptyProcess.on 'terminal-plus:data', (data) =>
        @terminal.write data

    @ptyProcess.on 'terminal-plus:exit', (data) =>
      @destroy()

    @ptyProcess.send event: 'input', text: ' clear\r'

    @terminal.end = => @destroy()

    @terminal.on "data", (data) =>
      @input data

    @terminal.once "title", (title) =>
      @terminal.on 'title', (title) =>
        @statusIcon.tooltip.dispose() if @statusIcon.tooltip?
        @statusIcon.tooltip = atom.tooltips.add @statusIcon, title: title

  clearStatusIcon: () ->
    @statusIcon.removeClass()
    @statusIcon.addClass('icon icon-terminal')

  setWindowSizeBoundary: ->
    @maxHeight = atom.config.get('terminal-plus.style.maxPanelHeight')
    @xterm.css("max-height", "#{@maxHeight}px")
    @xterm.css("min-height", "#{@minHeight}px")

  flashIconClass: (className, time=100)=>
    @statusIcon.addClass className
    @timer and clearTimeout(@timer)
    onStatusOut = =>
      @statusIcon.removeClass className
    @timer = setTimeout onStatusOut, time

  destroy: ->
    @statusIcon.remove()
    @statusBar.removeTerminalView this
    @detachResizeEvents()

    if @hasParent()
      @close()
    if @statusIcon and @statusIcon.parentNode
      @statusIcon.parentNode.removeChild(@statusIcon)

    @ptyProcess?.terminate()
    @terminal?.destroy()
    return

  maximize: ->
    @xterm.height (@maxHeight)

  open: ->
    atom.workspace.addBottomPanel(item: this) unless @hasParent()
    if lastOpenedView and lastOpenedView != this
      lastOpenedView.close()
    lastOpenedView = this
    @statusIcon.addClass 'active'
    @setWindowSizeBoundary()
    @statusBar.setActiveTerminalView this

    atom.tooltips.add @exitBtn,
     title: 'Destroy the terminal session.'
    atom.tooltips.add @closeBtn,
     title: 'Hide the terminal window.'
    atom.tooltips.add @openConfigBtn,
     title: 'Open the terminal config file.'
    atom.tooltips.add @reloadConfigBtn,
     title: 'Reload the terminal configuration.'

    if atom.config.get('terminal-plus.toggles.windowAnimations')
      @WindowMinHeight = @xterm.height() + 50
      @height 0
      @animate {
        height: @opened && @WindowMinHeight || @maxHeight
      }, 250, () =>
        if not @opened
          @opened = true
          @displayTerminal()
        else
          @focusTerm()
        @attr 'style', ''

  close: ->
    if atom.config.get('terminal-plus.toggles.windowAnimations')
      @WindowMinHeight = @xterm.height() + 50
      @height @WindowMinHeight
      @animate {
        height: 0
      }, 250, =>
        @attr 'style', ''
        @terminal.blur()
        @detach()
    else
      @detach()
    lastOpenedView = null
    @statusIcon.removeClass 'active'

  toggle: ->
    if @hasParent()
      @close()
    else
      @open()

  input: (data) ->
    @ptyProcess.send event: 'input', text: data
    @resizeToPanel()
    @focusTerm()

  resize: (cols, rows) ->
    @ptyProcess.send {event: 'resize', rows, cols}

  applyStyle: ->
    if @style?
      @xterm.removeClass @style.theme
    @style = atom.config.get 'terminal-plus.style'

    @xterm.addClass @style.theme
    @terminal.element.style.backgroundColor = 'inherit'
    @terminal.element.style.color = 'inherit'

    fontFamily = ["monospace"]
    fontFamily.unshift atom.config.get('editor.fontFamily') unless not atom.config.get('editor.fontFamily')
    fontFamily.unshift @style.fontFamily unless not @style.fontFamily

    @terminal.element.style.fontFamily = fontFamily.join ', '
    @terminal.element.style.fontSize = (
      (@style.fontSize == 0) and
      (atom.config.get('editor.fontSize') + "px") or
      (@style.fontSize + 'px')
    )

  attachResizeEvents: ->
    @on 'focus', @focus
    $(window).on 'resize', @resizeToPanel
    @panelDivider.on 'mousedown', @resizeStarted.bind(this)

  detachResizeEvents: ->
    @off 'focus', @focus
    $(window).off 'resize'
    @panelDivider.off 'mousedown'

  attachEvents: ->
    @resizeToPanel = @resizeToPanel.bind this
    @resizePane = @resizePanel.bind(this)
    @resizeStopped = @resizeStopped.bind(this)
    @attachResizeEvents()

    atom.commands.add "atom-workspace", "terminal-plus:paste", => @paste()
    atom.commands.add "atom-workspace", "terminal-plus:copy", => @copy()

  resizeStarted: (e) ->
    $(document).on('mousemove', @resizePanel)
    $(document).on('mouseup', @resizeStopped)
    console.log e

  resizeStopped: ->
    $(document).off('mousemove', @resizePanel)
    $(document).off('mouseup', @resizeStopped)

  clampResize: (height) =>
    return Math.max(Math.min(@maxHeight, height), @minHeight)

  resizePanel: (event) =>
    return @resizeStopped() unless event.which is 1

    mouseY = $(window).height() - event.pageY
    delta = mouseY - $('atom-panel-container.bottom').height()
    clamped = @clampResize (@xterm.height() + delta)
    
    @xterm.height clamped
    $(@terminal.element).height clamped

    @resizeTerminalToView()

  copy: ->
    if  @terminal._selected  # term.js visual mode selections
      textarea = @terminal.getCopyTextarea()
      text = @terminal.grabText(
        @terminal._selected.x1, @terminal._selected.x2,
        @terminal._selected.y1, @terminal._selected.y2)
    else # fallback to DOM-based selections
      rawText = @terminal.context.getSelection().toString()
      rawLines = rawText.split(/\r?\n/g)
      lines = rawLines.map (line) ->
        line.replace(/\s/g, " ").trimRight()
      text = lines.join("\n")
    atom.clipboard.write text

  paste: ->
    @input atom.clipboard.read()

  focus: ->
    @resizeToPanel
    @focusTerm

  focusTerm: ->
    @terminal.element.focus()
    @terminal.focus()

  resizeToPanel: ->
    {cols, rows} = @getDimensions()
    return unless cols > 0 and rows > 0
    return unless @terminal
    return if @terminal.rows is rows and @terminal.cols is cols

    @resize cols, rows
    @terminal.resize cols, rows

  getDimensions: ->
    fakeRow = $("<div><span>&nbsp;</span></div>").css visibility: 'hidden'
    if @terminal
      @find('.terminal').append fakeRow
      fakeCol = fakeRow.children().first()
      cols = Math.floor(@xterm.width() / fakeCol.width()) or 9
      rows = Math.floor (@xterm.height() / fakeCol.height()) or 16
      @minHeight = fakeCol.height()
      fakeRow.remove()
    else
      cols = Math.floor @width() / 7
      rows = Math.floor @height() / 14

    {cols, rows}
