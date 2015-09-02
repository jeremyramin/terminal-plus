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
      @div class: 'panel-divider', style: 'cursor:row-resize; width:100%; height: 2px;', outlet: 'panelDivider'
      @div class: 'panel-heading btn-toolbar', outlet:'viewToolbar', =>
        @button outlet: 'closeBtn', class: 'btn inline-block-tight right', click: 'destroy', =>
          @i class: 'icon icon-x', ' '
          @span 'Close'
        @button outlet: 'hideBtn', class: 'btn inline-block-tight right', click: 'hide', =>
          @i class: 'icon icon-chevron-down', ' '
          @span 'Hide'

      @div class: 'xterm', outlet: 'xterm'

  constructor: ->
    editorPath = keypather.get atom, 'workspace.getEditorViews[0].getEditor().getPath()'
    @pwd = atom.project.getPaths()[0] or editorPath or process.env.HOME
    @subscriptions = new CompositeDisposable
    super

  initialize: ->
    @subscriptions.add atom.tooltips.add @closeBtn,
      title: 'Destroy the terminal session.'
    @subscriptions.add atom.tooltips.add @hideBtn,
      title: 'Hide the terminal window.'

    @animating = $.Deferred().resolve()

  forkPtyProcess: (shell, args=[]) ->
    project = atom.project.getPaths()[0] ? '~'
    Task.once Pty, path.resolve(project), shell, args

  displayTerminal: ->
    {cols, rows} = @getDimensions()
    shell = atom.config.get 'terminal-plus.core.shell'
    shellArguments = atom.config.get 'terminal-plus.core.shellArguments'
    args = shellArguments.split(/\s+/g).filter (arg)-> arg
    @ptyProcess = @forkPtyProcess shell, args

    @terminal = new Terminal {
      colors          : @xtermColors
      cursorBlink     : atom.config.get 'terminal-plus.toggles.cursorBlink'
      scrollback      : atom.config.get 'terminal-plus.core.scrollback'
      cols, rows
    }

    @attachListeners()

    @terminal.open @xterm.get(0)

    @applyStyle()
    @attachEvents()
    @resizeTerminalToView()

    onDisplay = =>
      @focusTerminal()
    setTimeout onDisplay, 300

  attachListeners: ->
    @ptyProcess.on 'terminal-plus:data', (data) =>
      @terminal.write data

    @ptyProcess.on 'terminal-plus:exit', (data) =>
      @destroy()

    @ptyProcess.on 'terminal-plus:title', (title) =>
      @statusIcon.updateTooltip(title)

    @ptyProcess.on 'terminal-plus:clear-title', =>
      @statusIcon.removeTooltip()

    @terminal.end = => @destroy()

    @terminal.on "data", (data) =>
      @input data

    @terminal.once "open", =>
      switch atom.config.get('terminal-plus.core.workingDirectory')
        when 'Project' then cwd = @pwd
        when 'Active File' then cwd = path.dirname atom.workspace.getActiveTextEditor()?.getPath()
        else cwd = null

      autoRunCommand = atom.config.get('terminal-plus.core.autoRunCommand')

      @input "cd #{cwd}; clear; pwd#{os.EOL}" if cwd?
      @input "#{autoRunCommand}#{os.EOL}" if autoRunCommand

  setViewSizeBoundary: ->
    @maxHeight = atom.config.get('terminal-plus.style.maxPanelHeight')
    @xterm.css("max-height", "#{@maxHeight}px")
    @xterm.css("min-height", "#{@minHeight}px")

  destroy: ->
    @hide().done(=> @_destroy())

  _destroy: ->
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

  open: (@animating=$.Deferred()) ->
    @panel.show()

    if lastOpenedView and lastOpenedView != this
      lastOpenedView.hide()
    lastOpenedView = this
    @statusBar.setActiveTerminalView this
    @statusIcon.classList.add 'active'
    @setViewSizeBoundary()

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
        @animating.resolve('Opened')
    else
      @animating.resolve('Opened')

    @animating

  hide: (@animating=$.Deferred()) ->
    @terminal?.blur()
    lastOpenedView = null
    @statusIcon.classList.remove 'active'

    if atom.config.get('terminal-plus.toggles.windowAnimations')
      @WindowMinHeight = @xterm.height() + 50
      @height @WindowMinHeight
      @animate {
        height: 0
      }, 250, =>
        @attr 'style', ''
        @panel.hide()
        @animating.resolve('Hidden')
    else
      @panel.hide()
      @animating.resolve('Hidden')

    @animating

  toggle: ->
    return unless @animating.state() is "resolved"
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

  resizeStarted: ->
    $(document).on('mousemove', @resizePanel)
    $(document).on('mouseup', @resizeStopped)

  resizeStopped: ->
    $(document).off('mousemove', @resizePanel)
    $(document).off('mouseup', @resizeStopped)

  clampResize: (height) ->
    return Math.max(Math.min(@maxHeight, height), @minHeight)

  resizePanel: (event) ->
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
