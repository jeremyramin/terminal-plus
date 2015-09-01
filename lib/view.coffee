path = require 'path'
os = require 'os'
keypather = do require 'keypather'

{Task, CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

Pty = require.resolve './process'
Terminal = require 'term.js'

lastOpenedView = null

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
      @div class: 'panel-heading btn-toolbar', outlet:'viewToolbar', =>
        # @div class: 'btn-group', outlet:'consoleToolbar', =>
        @button outlet: 'hideBtn', class: 'btn icon icon-chevron-down inline-block-tight', click: 'hide', =>
          @span 'Hide'
        @button outlet: 'closeBtn', class: 'btn icon icon-x inline-block-tight', click: 'destroy', =>
          @span 'Close'
      @div class: 'xterm', outlet: 'xterm'

  constructor: (@opts={})->
    if opts.shellOverride
      opts.shell = opts.shellOverride
    else
      opts.shell = process.env.SHELL or 'bash'
    opts.shellArguments or= ''
    editorPath = keypather.get atom, 'workspace.getEditorViews[0].getEditor().getPath()'
    opts.cwd = opts.cwd or atom.project.getPaths()[0] or editorPath or process.env.HOME
    @subscriptions = new CompositeDisposable
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

    @terminal = new Terminal {
      colors: @xtermColors
      cursorBlink, scrollback, cols, rows
    }

    @setupListeners()

    @terminal.open @xterm.get(0)
    @input "#{runCommand}#{os.EOL}" if runCommand

    @applyStyle()
    @attachEvents()
    @resizeTerminalToView()

    onDisplay = =>
      @focusTerminal()
    setTimeout onDisplay, 300

  setupListeners: () ->
    @ptyProcess.send event: 'input', text: ' clear\r'

    @ptyProcess.once 'terminal-plus:data', (chunk) =>

      @ptyProcess.on 'terminal-plus:data', (data) =>
        @terminal.write data

    @ptyProcess.on 'terminal-plus:exit', (data) =>
      @destroy()

    @terminal.end = => @destroy()

    @terminal.on "data", (data) =>
      @input data

    @terminal.once "title", (title) =>
      @terminal.on 'title', (title) =>
        @statusIcon.tooltip.dispose() if @statusIcon.tooltip?
        @statusIcon.tooltip = atom.tooltips.add @statusIcon,
          title: title
          html: false
          delay:
            show: 500
            hide: 250

  setWindowSizeBoundary: ->
    @maxHeight = atom.config.get('terminal-plus.style.maxPanelHeight')
    @xterm.css("max-height", "#{@maxHeight}px")
    @xterm.css("min-height", "#{@minHeight}px")

  flashIconClass: (className, time=100)=>
    @statusIcon.classList.add className
    @timer and clearTimeout(@timer)
    onStatusOut = =>
      @statusIcon.classList.remove className
    @timer = setTimeout onStatusOut, time

  destroy: ->
    @subscriptions.dispose()
    @statusIcon.remove()
    @statusBar.removeTerminalView this
    @detachResizeEvents()

    if @panel.isVisible()
      @hide()
    if @statusIcon and @statusIcon.parentNode
      @statusIcon.parentNode.removeChild(@statusIcon)

    @panel.destroy()
    @ptyProcess?.terminate()
    @terminal?.destroy()
    return

  maximize: ->
    @xterm.height (@maxHeight)

  open: ->
    @panel.show()

    if lastOpenedView and lastOpenedView != this
      lastOpenedView.hide()
    lastOpenedView = this
    @statusIcon.classList.add 'active'
    @setWindowSizeBoundary()
    @statusBar.setActiveTerminalView this

    @subscriptions.add atom.tooltips.add @closeBtn,
     title: 'Destroy the terminal session.'
    @subscriptions.add atom.tooltips.add @hideBtn,
     title: 'Hide the terminal window.'

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
          @focusTerminal()
        @attr 'style', ''

  hide: ->
    if atom.config.get('terminal-plus.toggles.windowAnimations')
      @WindowMinHeight = @xterm.height() + 50
      @height @WindowMinHeight
      @animate {
        height: 0
      }, 250, =>
        @attr 'style', ''
        @panel.hide()
    else
      @panel.hide()
    @terminal?.blur()
    lastOpenedView = null
    @statusIcon.classList.remove 'active'

  toggle: ->
    if @panel.isVisible()
      @hide()
    else
      @open()

  input: (data) ->
    @ptyProcess.send event: 'input', text: data
    @resizeTerminalToView()
    @focusTerminal()

  resize: (cols, rows) ->
    @ptyProcess.send {event: 'resize', rows, cols}

  applyStyle: ->
    style = atom.config.get 'terminal-plus.style'

    @xterm.addClass style.theme
    @terminal.element.style.backgroundColor = 'inherit'
    @terminal.element.style.color = 'inherit'

    fontFamily = ["monospace"]
    fontFamily.unshift style.fontFamily unless style.fontFamily is ''
    @terminal.element.style.fontFamily = fontFamily.join ', '
    @terminal.element.style.fontSize = style.fontSize + 'px'

  attachResizeEvents: ->
    @on 'focus', @focus
    $(window).on 'resize', => @resizeTerminalToView() if @panel.isVisible()
    @panelDivider.on 'mousedown', @resizeStarted.bind(this)

  detachResizeEvents: ->
    @off 'focus', @focus
    $(window).off 'resize'
    @panelDivider.off 'mousedown'

  attachEvents: ->
    @resizeTerminalToView = @resizeTerminalToView.bind this
    @resizePanel = @resizePanel.bind(this)
    @resizeStopped = @resizeStopped.bind(this)
    @attachResizeEvents()

  resizeStarted: (e) ->
    $(document).on('mousemove', @resizePanel)
    $(document).on('mouseup', @resizeStopped)

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
    @resizeTerminalToView
    @focusTerminal

  focusTerminal: ->
    @terminal.focus()
    @terminal.element.focus()

  resizeTerminalToView: ->
    {cols, rows} = @getDimensions()
    return unless cols > 0 and rows > 0
    return unless @terminal
    return if @terminal.rows is rows and @terminal.cols is cols

    @resize cols, rows
    @terminal.resize cols, rows

  getDimensions: ->
    fakeRow = $("<div><span>&nbsp;</span></div>")
    if @terminal
      @find('.terminal').append fakeRow
      fakeCol = fakeRow.children().first()[0].getBoundingClientRect()
      cols = Math.floor(@xterm.width() / (fakeCol.width or 9))
      rows = Math.floor (@xterm.height() / (fakeCol.height or 20))
      @minHeight = fakeCol.height
      fakeRow.remove()
    else
      cols = Math.floor @xterm.width() / 9
      rows = Math.floor @xterm.height() / 20

    {cols, rows}
