{Task, CompositeDisposable, Emitter} = require 'atom'
{$, View} = require 'atom-space-pen-views'

Pty = require.resolve './process'
Terminal = require 'term.js'
InputDialog = null

path = require 'path'
os = require 'os'

lastOpenedView = null
lastActiveElement = null

module.exports =
class PlatformIOTerminalView extends View
  animating: false
  id: ''
  maximized: false
  opened: false
  pwd: ''
  windowHeight: $(window).height()
  rowHeight: 20
  shell: ''
  tabView: false

  @content: ->
    @div class: 'platformio-ide-terminal terminal-view', outlet: 'platformIOTerminalView', =>
      @div class: 'panel-divider', outlet: 'panelDivider'
      @section class: 'input-block', =>
        @div class: 'btn-toolbar', =>
          @div class: 'btn-group', =>
            @button outlet: 'inputBtn', class: 'btn icon icon-keyboard', click: 'inputDialog'
          @div class: 'btn-group right', =>
            @button outlet: 'hideBtn', class: 'btn icon icon-chevron-down', click: 'hide'
            @button outlet: 'maximizeBtn', class: 'btn icon icon-screen-full', click: 'maximize'
            @button outlet: 'closeBtn', class: 'btn icon icon-x', click: 'destroy'
      @div class: 'xterm', outlet: 'xterm'

  @getFocusedTerminal: ->
    return Terminal.Terminal.focus

  initialize: (@id, @pwd, @statusIcon, @statusBar, @shell, @args=[], @env={}, @autoRun=[]) ->
    @subscriptions = new CompositeDisposable
    @emitter = new Emitter

    @subscriptions.add atom.tooltips.add @closeBtn,
      title: 'Close'
    @subscriptions.add atom.tooltips.add @hideBtn,
      title: 'Hide'
    @subscriptions.add @maximizeBtn.tooltip = atom.tooltips.add @maximizeBtn,
      title: 'Fullscreen'
    @inputBtn.tooltip = atom.tooltips.add @inputBtn,
      title: 'Insert Text'

    @prevHeight = atom.config.get('platformio-ide-terminal.style.defaultPanelHeight')
    if @prevHeight.indexOf('%') > 0
      percent = Math.abs(Math.min(parseFloat(@prevHeight) / 100.0, 1))
      bottomHeight = $('atom-panel.bottom').children(".terminal-view").height() or 0
      @prevHeight = percent * ($('.item-views').height() + bottomHeight)
    @xterm.height 0

    @setAnimationSpeed()
    @subscriptions.add atom.config.onDidChange 'platformio-ide-terminal.style.animationSpeed', @setAnimationSpeed

    override = (event) ->
      return if event.originalEvent.dataTransfer.getData('platformio-ide-terminal') is 'true'
      event.preventDefault()
      event.stopPropagation()

    @xterm.on 'mouseup', (event) =>
      if event.which != 3
        text = window.getSelection().toString()
        if atom.config.get('platformio-ide-terminal.toggles.selectToCopy') and text
          rawLines = text.split(/\r?\n/g)
          lines = rawLines.map (line) ->
            line.replace(/\s/g, " ").trimRight()
          text = lines.join("\n")
          atom.clipboard.write(text)
        unless text
          @focus()
    @xterm.on 'dragenter', override
    @xterm.on 'dragover', override
    @xterm.on 'drop', @recieveItemOrFile

    @on 'focus', @focus
    @subscriptions.add dispose: =>
      @off 'focus', @focus

    if /zsh|bash/.test(@shell) and @args.indexOf('--login') == -1 and Pty.platform isnt 'win32' and atom.config.get('platformio-ide-terminal.toggles.loginShell')
      @args.unshift '--login'

  attach: ->
    return if @panel?
    @panel = atom.workspace.addBottomPanel(item: this, visible: false)

  setAnimationSpeed: =>
    @animationSpeed = atom.config.get('platformio-ide-terminal.style.animationSpeed')
    @animationSpeed = 100 if @animationSpeed is 0

    @xterm.css 'transition', "height #{0.25 / @animationSpeed}s linear"

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

  forkPtyProcess: ->
    Task.once Pty, path.resolve(@pwd), @shell, @args, @env, =>
      @input = ->
      @resize = ->

  getId: ->
    return @id

  displayTerminal: ->
    {cols, rows} = @getDimensions()
    @ptyProcess = @forkPtyProcess()

    @terminal = new Terminal {
      cursorBlink     : false
      scrollback      : atom.config.get 'platformio-ide-terminal.core.scrollback'
      cols, rows
    }

    @attachListeners()
    @attachResizeEvents()
    @attachWindowEvents()
    @terminal.open @xterm.get(0)

  attachListeners: ->
    @ptyProcess.on "platformio-ide-terminal:data", (data) =>
      @terminal.write data

    @ptyProcess.on "platformio-ide-terminal:exit", =>
      @destroy() if atom.config.get('platformio-ide-terminal.toggles.autoClose')

    @terminal.end = => @destroy()

    @terminal.on "data", (data) =>
      @input data

    @ptyProcess.on "platformio-ide-terminal:title", (title) =>
      @process = title
    @terminal.on "title", (title) =>
      @title = title

    @terminal.once "open", =>
      @applyStyle()
      @resizeTerminalToView()

      return unless @ptyProcess.childProcess?
      autoRunCommand = atom.config.get('platformio-ide-terminal.core.autoRunCommand')
      @input "#{autoRunCommand}#{os.EOL}" if autoRunCommand
      @input "#{command}#{os.EOL}" for command in @autoRun

  destroy: ->
    @subscriptions.dispose()
    @statusIcon.destroy()
    @statusBar.removeTerminalView this
    @detachResizeEvents()
    @detachWindowEvents()

    if @panel.isVisible()
      @hide()
      @onTransitionEnd => @panel.destroy()
    else
      @panel.destroy()

    if @statusIcon and @statusIcon.parentNode
      @statusIcon.parentNode.removeChild(@statusIcon)

    @ptyProcess?.terminate()
    @terminal?.destroy()

  maximize: ->
    @subscriptions.remove @maximizeBtn.tooltip
    @maximizeBtn.tooltip.dispose()

    @maxHeight = @prevHeight + atom.workspace.getCenter().paneContainer.element.offsetHeight
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
      if lastOpenedView.maximized
        @subscriptions.remove @maximizeBtn.tooltip
        @maximizeBtn.tooltip.dispose()
        icon = @maximizeBtn.children('span')

        @maxHeight = lastOpenedView.maxHeight
        @maximizeBtn.tooltip = atom.tooltips.add @maximizeBtn,
          title: 'Normal'
        @subscriptions.add @maximizeBtn.tooltip
        icon.removeClass('icon-screen-full').addClass('icon-screen-normal')
        @maximized = true
      lastOpenedView.hide()

    lastOpenedView = this
    @statusBar.setActiveTerminalView this
    @statusIcon.activate()

    @onTransitionEnd =>
      if not @opened
        @opened = true
        @displayTerminal()
        @prevHeight = @nearestRow(@xterm.height())
        @xterm.height(@prevHeight)
        @emit "platformio-ide-terminal:terminal-open"
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
    return unless @ptyProcess.childProcess?

    @terminal.stopScrolling()
    @ptyProcess.send event: 'input', text: data

  resize: (cols, rows) ->
    return unless @ptyProcess.childProcess?

    @ptyProcess.send {event: 'resize', rows, cols}

  pty: () ->
    if not @opened
      wait = new Promise (resolve, reject) =>
        @emitter.on "platformio-ide-terminal:terminal-open", () =>
          resolve()
        setTimeout reject, 1000

      wait.then () =>
        @ptyPromise()
    else
      @ptyPromise()

  ptyPromise: () ->
    new Promise (resolve, reject) =>
      if @ptyProcess?
        @ptyProcess.on "platformio-ide-terminal:pty", (pty) =>
          resolve(pty)
        @ptyProcess.send {event: 'pty'}
        setTimeout reject, 1000
      else
        reject()

  applyStyle: ->
    config = atom.config.get 'platformio-ide-terminal'

    @xterm.addClass config.style.theme
    @xterm.addClass 'cursor-blink' if config.toggles.cursorBlink

    editorFont = atom.config.get('editor.fontFamily')
    defaultFont = "Menlo, Consolas, 'DejaVu Sans Mono', monospace"
    overrideFont = config.style.fontFamily
    @terminal.element.style.fontFamily = overrideFont or editorFont or defaultFont

    @subscriptions.add atom.config.onDidChange 'editor.fontFamily', (event) =>
      editorFont = event.newValue
      @terminal.element.style.fontFamily = overrideFont or editorFont or defaultFont
    @subscriptions.add atom.config.onDidChange 'platformio-ide-terminal.style.fontFamily', (event) =>
      overrideFont = event.newValue
      @terminal.element.style.fontFamily = overrideFont or editorFont or defaultFont

    editorFontSize = atom.config.get('editor.fontSize')
    overrideFontSize = config.style.fontSize
    @terminal.element.style.fontSize = "#{overrideFontSize or editorFontSize}px"

    @subscriptions.add atom.config.onDidChange 'editor.fontSize', (event) =>
      editorFontSize = event.newValue
      @terminal.element.style.fontSize = "#{overrideFontSize or editorFontSize}px"
      @resizeTerminalToView()
    @subscriptions.add atom.config.onDidChange 'platformio-ide-terminal.style.fontSize', (event) =>
      overrideFontSize = event.newValue
      @terminal.element.style.fontSize = "#{overrideFontSize or editorFontSize}px"
      @resizeTerminalToView()

    # first 8 colors i.e. 'dark' colors
    @terminal.colors[0..7] = [
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
    @terminal.colors[8..15] = [
      config.ansiColors.zBright.brightBlack.toHexString()
      config.ansiColors.zBright.brightRed.toHexString()
      config.ansiColors.zBright.brightGreen.toHexString()
      config.ansiColors.zBright.brightYellow.toHexString()
      config.ansiColors.zBright.brightBlue.toHexString()
      config.ansiColors.zBright.brightMagenta.toHexString()
      config.ansiColors.zBright.brightCyan.toHexString()
      config.ansiColors.zBright.brightWhite.toHexString()
    ]

  attachWindowEvents: ->
    $(window).on 'resize', @onWindowResize

  detachWindowEvents: ->
    $(window).off 'resize', @onWindowResize

  attachResizeEvents: ->
    @panelDivider.on 'mousedown', @resizeStarted

  detachResizeEvents: ->
    @panelDivider.off 'mousedown'

  onWindowResize: =>
    if not @tabView
      @xterm.css 'transition', ''
      newHeight = $(window).height()
      bottomPanel = $('atom-panel-container.bottom').first().get(0)
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

      @xterm.css 'transition', "height #{0.25 / @animationSpeed}s linear"
    @resizeTerminalToView()

  resizeStarted: =>
    return if @maximized
    @maxHeight = @prevHeight + $('.item-views').height()
    $(document).on('mousemove', @resizePanel)
    $(document).on('mouseup', @resizeStopped)
    @xterm.css 'transition', ''

  resizeStopped: =>
    $(document).off('mousemove', @resizePanel)
    $(document).off('mouseup', @resizeStopped)
    @xterm.css 'transition', "height #{0.25 / @animationSpeed}s linear"

  nearestRow: (value) ->
    rows = value // @rowHeight
    return rows * @rowHeight

  resizePanel: (event) =>
    return @resizeStopped() unless event.which is 1

    mouseY = $(window).height() - event.pageY
    delta = mouseY - $('atom-panel-container.bottom').height() - $('atom-panel-container.footer').height()
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
    if @terminal._selected
      textarea = @terminal.getCopyTextarea()
      text = @terminal.grabText(
        @terminal._selected.x1, @terminal._selected.x2,
        @terminal._selected.y1, @terminal._selected.y2)
    else
      rawText = @terminal.context.getSelection().toString()
      rawLines = rawText.split(/\r?\n/g)
      lines = rawLines.map (line) ->
        line.replace(/\s/g, " ").trimRight()
      text = lines.join("\n")
    atom.clipboard.write text

  paste: ->
    @input atom.clipboard.read()

  insertSelection: (customText) ->
    return unless editor = atom.workspace.getActiveTextEditor()
    runCommand = atom.config.get('platformio-ide-terminal.toggles.runInsertedText')
    selectionText = ''
    if selection = editor.getSelectedText()
      @terminal.stopScrolling()
      selectionText = selection
    else if cursor = editor.getCursorBufferPosition()
      line = editor.lineTextForBufferRow(cursor.row)
      @terminal.stopScrolling()
      selectionText = line
      editor.moveDown(1);
    @input "#{customText.
      replace(/\$L/, "#{editor.getCursorBufferPosition().row + 1}").
      replace(/\$F/, path.basename(if editor.buffer.getPath() then editor.buffer.getPath() else '.')).
      replace(/\$D/, path.dirname(if editor.buffer.getPath() then editor.buffer.getPath() else '.')).
      replace(/\$S/, selectionText).
      replace(/\$\$/, '$')}#{if runCommand then os.EOL else ''}"

  focus: (fromWindowEvent) =>
    @resizeTerminalToView()
    @focusTerminal(fromWindowEvent)
    @statusBar.setActiveTerminalView(this)
    super()

  blur: =>
    @blurTerminal()
    super()

  focusTerminal: (fromWindowEvent) =>
    return unless @terminal

    lastActiveElement = $(document.activeElement)
    return if fromWindowEvent and not (lastActiveElement.is('div.terminal') or lastActiveElement.parents('div.terminal').length)

    @terminal.focus()
    if @terminal._textarea
      @terminal._textarea.focus()
    else
      @terminal.element.focus()

  blurTerminal: =>
    return unless @terminal

    @terminal.blur()
    @terminal.element.blur()

    if lastActiveElement?
      lastActiveElement.focus()

  resizeTerminalToView: ->
    return unless @panel.isVisible() or @tabView

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

  inputDialog: ->
    InputDialog ?= require('./input-dialog')
    dialog = new InputDialog this
    dialog.attach()

  rename: ->
    @statusIcon.rename()

  toggleTabView: ->
    if @tabView
      @panel = atom.workspace.addBottomPanel(item: this, visible: false)
      @attachResizeEvents()
      @closeBtn.show()
      @hideBtn.show()
      @maximizeBtn.show()
      @tabView = false
    else
      @panel.destroy()
      @detachResizeEvents()
      @closeBtn.hide()
      @hideBtn.hide()
      @maximizeBtn.hide()
      @xterm.css "height", ""
      @tabView = true
      lastOpenedView = null if lastOpenedView == this

  getTitle: ->
    @statusIcon.getName() or "platformio-ide-terminal"

  getIconName: ->
    "terminal"

  getShell: ->
    return path.basename @shell

  getShellPath: ->
    return @shell

  emit: (event, data) ->
    @emitter.emit event, data

  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback

  getPath: ->
    return @getTerminalTitle()

  getTerminalTitle: ->
    return @title or @process

  getTerminal: ->
    return @terminal

  isAnimating: ->
    return @animating
