{Task, CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

Pty = require.resolve './process'
Terminal = require 'term.js'

path = require 'path'
os = require 'os'

lastOpenedView = null
lastActiveElement = null

module.exports =
class TerminalPlusView extends View
  opened: false
  animating: false
  windowHeight: $(window).height()

  @content: ->
    @div class: 'terminal-plus terminal-view', outlet: 'terminalPlusView', =>
      @div class: 'panel-divider', outlet: 'panelDivider'
      @div class: 'btn-toolbar', outlet:'toolbar', =>
        @button outlet: 'closeBtn', class: 'btn inline-block-tight right', click: 'destroy', =>
          @span class: 'icon icon-x'
        @button outlet: 'hideBtn', class: 'btn inline-block-tight right', click: 'hide', =>
          @span class: 'icon icon-chevron-down'
        @button outlet: 'maximizeBtn', class: 'btn inline-block-tight right', click: 'maximize', =>
          @span class: 'icon icon-screen-full'
      @div class: 'xterm', outlet: 'xterm'

  initialize: ->
    @subscriptions = new CompositeDisposable()

    @subscriptions.add atom.tooltips.add @closeBtn,
      title: 'Close'
    @subscriptions.add atom.tooltips.add @hideBtn,
      title: 'Hide'
    @maximizeBtn.tooltip = atom.tooltips.add @maximizeBtn,
      title: 'Fullscreen'
    @subscriptions.add @maximizeBtn.tooltip

    @prevHeight = atom.config.get('terminal-plus.style.defaultPanelHeight')
    @xterm.height 0

    @setAnimationSpeed()
    atom.config.onDidChange('terminal-plus.style.animationSpeed', @setAnimationSpeed)

    override = (event) ->
      return if event.originalEvent.dataTransfer.getData('terminal-plus') is 'true'
      event.preventDefault()
      event.stopPropagation()

    @xterm.on 'click', @focus

    @xterm.on 'dragenter', override
    @xterm.on 'dragover', override
    @xterm.on 'drop', @recieveItemOrFile

  setAnimationSpeed: =>
    @animationSpeed = atom.config.get('terminal-plus.style.animationSpeed')
    @animationSpeed = 100 if @animationSpeed is 0

    @xterm.css 'transition', "height #{0.25 / @animationSpeed}s linear"

  recieveItemOrFile: (event) =>
    event.preventDefault()
    event.stopPropagation()
    {dataTransfer} = event.originalEvent

    if dataTransfer.getData('atom-event') is 'true'
      @input "#{dataTransfer.getData('text/plain')} "
    else if filePath = dataTransfer.getData('initialPath')
      @input "#{filePath} "
    else if dataTransfer.files.length > 0
      for file in dataTransfer.files
        @input "#{file.path} "

  forkPtyProcess: (shell, args=[]) ->
    projectFolder = atom.project.getPaths()[0]
    editorPath = atom.workspace.getActiveTextEditor()?.getPath()
    editorFolder = path.dirname(editorPath) if editorPath?
    home = if process.platform is 'win32' then process.env.HOMEPATH else process.env.HOME

    switch atom.config.get('terminal-plus.core.workingDirectory')
      when 'Project' then pwd = projectFolder or editorFolder or home
      when 'Active File' then pwd = editorFolder or projectFolder or home
      else pwd = home

    Task.once Pty, path.resolve(pwd), shell, args

  displayTerminal: ->
    {cols, rows} = @getDimensions()
    shell = atom.config.get 'terminal-plus.core.shell'
    shellArguments = atom.config.get 'terminal-plus.core.shellArguments'
    args = shellArguments.split(/\s+/g).filter (arg)-> arg
    @ptyProcess = @forkPtyProcess shell, args

    @terminal = new Terminal {
      cursorBlink     : atom.config.get 'terminal-plus.toggles.cursorBlink'
      scrollback      : atom.config.get 'terminal-plus.core.scrollback'
      cols, rows
    }

    @attachListeners()
    @attachEvents()
    @terminal.open @xterm.get(0)

  attachListeners: ->
    @ptyProcess.on 'terminal-plus:data', (data) =>
      @terminal.write data

    @ptyProcess.on 'terminal-plus:exit', =>
      @input = ->
      @resize = ->
      @destroy() if atom.config.get('terminal-plus.toggles.autoClose')

    @ptyProcess.on 'terminal-plus:title', (title) =>
      @statusIcon.updateTooltip(title)

    @ptyProcess.on 'terminal-plus:clear-title', =>
      @statusIcon.removeTooltip()

    @terminal.end = => @destroy()

    @terminal.on "data", (data) =>
      @input data

    @terminal.once "open", =>
      @applyStyle()
      @focus()
      autoRunCommand = atom.config.get('terminal-plus.core.autoRunCommand')
      @input "#{autoRunCommand}#{os.EOL}" if autoRunCommand

  destroy: ->
    @subscriptions.dispose()
    @statusIcon.remove()
    @statusBar.removeTerminalView this
    @detachResizeEvents()

    if @panel.isVisible()
      @hide()
      @onTransitionEnd => @panel.destroy()
    if @statusIcon and @statusIcon.parentNode
      @statusIcon.parentNode.removeChild(@statusIcon)

    @ptyProcess?.terminate()
    @terminal?.destroy()

  maximize: ->
    @subscriptions.remove @maximizeBtn.tooltip
    @maximizeBtn.tooltip.dispose()

    @maxHeight = @prevHeight + $('.item-views').height()
    @xterm.css 'height', ''
    btn = @maximizeBtn.children('span')
    @onTransitionEnd => @focus()

    if @maximized
      @maximizeBtn.tooltip = atom.tooltips.add @maximizeBtn,
        title: 'Fullscreen'
      @subscriptions.add @maximizeBtn.tooltip
      @adjustHeight @prevHeight
      btn.removeClass('icon-screen-normal').addClass('icon-screen-full')
      @maximized = false
    else
      @maximizeBtn.tooltip = atom.tooltips.add @maximizeBtn,
        title: 'Normal'
      @subscriptions.add @maximizeBtn.tooltip
      @adjustHeight @maxHeight
      btn.removeClass('icon-screen-full').addClass('icon-screen-normal')
      @maximized = true

  open: =>
    lastActiveElement ?= $(document.activeElement)

    if lastOpenedView and lastOpenedView != this
      lastOpenedView.hide()
    lastOpenedView = this
    @statusBar.setActiveTerminalView this
    @statusIcon.activate()

    @onTransitionEnd =>
      if not @opened
        @opened = true
        @displayTerminal()
      else
        @focus()

    @panel.show()
    @xterm.height 0
    @animating = true
    @xterm.height if @maximized then @maxHeight else @prevHeight

  hide: =>
    @terminal?.blur()
    lastOpenedView = null
    @statusIcon.deactivate()

    @onTransitionEnd =>
      @panel.hide()
      unless lastOpenedView?
        if lastActiveElement?
          lastActiveElement.focus()
          lastActiveElement = null

    @xterm.height if @maximized then @maxHeight else @prevHeight
    @animating = true
    @xterm.height 0

  toggle: ->
    return if @animating

    if @panel.isVisible()
      @hide()
    else
      @open()

  input: (data) ->
    @terminal.stopScrolling()
    @ptyProcess.send event: 'input', text: data
    @resizeTerminalToView()
    @focusTerminal()

  resize: (cols, rows) ->
    @ptyProcess.send {event: 'resize', rows, cols}

  applyStyle: ->
    style = atom.config.get 'terminal-plus.style'

    @xterm.addClass style.theme

    fontFamily = ["monospace"]
    fontFamily.unshift style.fontFamily unless style.fontFamily is ''
    @terminal.element.style.fontFamily = fontFamily.join ', '
    @terminal.element.style.fontSize = style.fontSize + 'px'

  attachResizeEvents: ->
    @on 'focus', @focus
    $(window).on 'resize', =>
      @xterm.css 'transition', ''
      newHeight = $(window).height()
      bottomPanel = $('atom-panel-container.bottom')[0]
      overflow = bottomPanel.scrollHeight - bottomPanel.offsetHeight

      delta = newHeight - @windowHeight
      @windowHeight = newHeight

      if @maximized
        clamped = Math.max(@maxHeight + delta, @rowHeight)

        @adjustHeight clamped if @panel.isVisible()
        @maxHeight = clamped

        @prevHeight = Math.min(@prevHeight, @maxHeight)
      else if overflow > 0
        clamped = Math.max(@nearestRow(@prevHeight + delta), @rowHeight)

        @adjustHeight clamped if @panel.isVisible()
        @prevHeight = clamped
      @resizeTerminalToView()
      @xterm.css 'transition', "height #{0.25 / @animationSpeed}s linear"
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
    return if @maximized
    @maxHeight = @prevHeight + $('.item-views').height()
    $(document).on('mousemove', @resizePanel)
    $(document).on('mouseup', @resizeStopped)
    @xterm.css 'transition', ''

  resizeStopped: ->
    $(document).off('mousemove', @resizePanel)
    $(document).off('mouseup', @resizeStopped)
    @xterm.css 'transition', "height #{0.25 / @animationSpeed}s linear"

  nearestRow: (value) ->
    rows = value // @rowHeight
    return rows * @rowHeight

  resizePanel: (event) ->
    return @resizeStopped() unless event.which is 1

    mouseY = $(window).height() - event.pageY
    delta = mouseY - $('atom-panel-container.bottom').height()
    return unless Math.abs(delta) > (@rowHeight * 5 / 6)

    clamped = Math.max(@nearestRow(@prevHeight + delta), @rowHeight)
    return if clamped > @maxHeight

    @xterm.height clamped
    $(@terminal.element).height clamped
    @prevHeight = clamped

    @resizeTerminalToView()

  adjustHeight: (height) ->
    @xterm.height height
    $(@terminal.element).height height

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

  insertSelection: ->
    return unless editor = atom.workspace.getActiveTextEditor()
    if selection = editor.getSelectedText()
      @terminal.stopScrolling()
      @ptyProcess.send event: 'input', text: "#{selection}#{os.EOL}"
    else if cursor = editor.getCursorBufferPosition()
      line = editor.lineTextForBufferRow(cursor.row)
      @terminal.stopScrolling()
      @ptyProcess.send event: 'input', text: "#{line}#{os.EOL}"
      editor.moveDown(1);

  focus: =>
    @resizeTerminalToView()
    @focusTerminal()

  focusTerminal: ->
    @terminal.focus()
    @terminal.element.focus()

  resizeTerminalToView: ->
    return unless @panel.isVisible()

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
      cols = Math.floor @xterm.width() / (fakeCol.width or 9)
      rows = Math.floor @xterm.height() / (fakeCol.height or 20)
      @rowHeight = fakeCol.height
      fakeRow.remove()
    else
      cols = Math.floor @xterm.width() / 9
      rows = Math.floor @xterm.height() / 20

    {cols, rows}

  onTransitionEnd: (callback) ->
    @xterm.one 'webkitTransitionEnd', =>
      callback()
      @animating = false
