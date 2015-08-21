util       = require 'util'
path       = require 'path'
os         = require 'os'
fs         = require 'fs-plus'
keypather = do require 'keypather'

{Task} = require 'atom'
{$, TextEditorView, View} = require 'atom-space-pen-views'

Core = require './core'
Pty = require.resolve './process'
Terminal = require 'term.js'

window.$ = window.jQuery = $
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
  env: {}
  @content: () ->
    @div tabIndex: -1, class: 'terminal-plus terminal-plus-view', outlet: 'terminalPlusView', =>
      @div class: 'panel-divider', style: 'cursor:n-resize; width:100%; height: 5px;', outlet: 'panelDivider'
      @div class: 'panel-heading btn-toolbar', outlet:'consoleToolbarHeading', =>
        # @div class: 'btn-group', outlet:'consoleToolbar', =>
        @button outlet: 'closeBtn', click: 'close', class: 'btn icon icon-chevron-down inline-block-tight right', =>
          @span 'close'
        @button outlet: 'openConfigBtn', class: 'btn icon icon-gear inline-block-tight right', click: 'showSettings', =>
          @span 'Open config'
        @button outlet: 'reloadConfigBtn', class: 'btn icon icon-sync inline-block-tight right', click: 'reloadSettings', =>
          @span 'Reload config'
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
    Task.once Pty, fs.absolute(path), sh, args

  displayTerminal: () ->
    {cols, rows} = @getDimensions()
    {cwd, shell, shellArguments, shellOverride, runCommand, colors, cursorBlink, scrollback} = @opts
    args = shellArguments.split(/\s+/g).filter (arg)-> arg
    @ptyProcess = @forkPtyProcess shellOverride, args

    colorsArray = colors.map (color) -> color.toHexString()
    @term = term = new Terminal {
      useStyle: false
      screenKeys: true
      colors: colorsArray
      cursorBlink, scrollback, cols, rows
    }

    @ptyProcess.on 'terminal-plus:data', (data) =>
      @term.write data
    @ptyProcess.on 'terminal-plus:exit', (data) =>
      @destroy()

    term.end = => @destroy()

    term.on "data", (data) =>
      @input data
      atom.tooltips.add @statusIcon, title: @getTitle()

    @term.open @find('.xterm').get(0)
    @input "#{runCommand}#{os.EOL}" if runCommand
    term.focus()

    @applyStyle()
    @attachEvents()
    @resizeToPanel()

    lastY = -1
    mouseDown = false
    panelDraggingActive = false
    @panelDivider
    .mousedown () => panelDraggingActive = true
    .mouseup () => panelDraggingActive = false
    $(document)
    .mousedown () => mouseDown = true
    .mouseup () => mouseDown = false
    .mousemove (e) =>
      if mouseDown and panelDraggingActive
        if lastY != -1
          delta = e.pageY - lastY
          @xterm.height @xterm.height() - delta
          @xterm.trigger('resize')
        lastY = e.pageY
      else
        lastY = -1

  clearStatusIcon: () ->
    @statusIcon.removeClass()
    @statusIcon.addClass('icon icon-terminal')

  setWindowSizeBoundary: ->
    @maxHeight = atom.config.get('terminal-plus.WindowHeight')
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
    @detachResizeEvents()
    @ptyProcess.terminate()
    @term.destroy()

    _destroy = =>
      if @hasParent()
        @close()
      if @statusIcon and @statusIcon.parentNode
        @statusIcon.parentNode.removeChild(@statusIcon)
      @statusView.removeCommandView this

      _destroy()

  maximize: ->
    @xterm.height (@xterm.height()+9999)

  open: ->
    # if (atom.config.get('terminal-plus.moveToCurrentDirOnOpen')) and (not @specsMode)
    #   @moveToCurrentDirectory()
    #   # Fix me!
    # if (atom.config.get('terminal-plus.moveToCurrentDirOnOpenLS')) and (not @specsMode)
    #   # Fix me!

    atom.workspace.addBottomPanel(item: this) unless @hasParent()
    if lastOpenedView and lastOpenedView != this
      lastOpenedView.close()
    lastOpenedView = this
    @statusIcon.addClass 'active'
    @setWindowSizeBoundary()
    @statusView.setActiveCommandView this

    atom.tooltips.add @exitBtn,
     title: 'Destroy the terminal session.'
    atom.tooltips.add @closeBtn,
     title: 'Hide the terminal window.'
    atom.tooltips.add @openConfigBtn,
     title: 'Open the terminal config file.'
    atom.tooltips.add @reloadConfigBtn,
     title: 'Reload the terminal configuration.'

    if atom.config.get 'terminal-plus.enableWindowAnimations'
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
    if atom.config.get 'terminal-plus.enableWindowAnimations'
      @WindowMinHeight = @xterm.height() + 50
      @height @WindowMinHeight
      @animate {
        height: 0
      }, 250, =>
        @attr 'style', ''
        @term.blur()
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

  titleVars: ->
    bashName: last @opts.shell.split '/'
    hostName: os.hostname()
    platform: process.platform
    home    : process.env.HOME

  getTitle: ->
    @vars = @titleVars()
    titleTemplate = @opts.titleTemplate or "({{ bashName }})"
    renderTemplate titleTemplate, @vars

  applyStyle: ->
    @term.element.style.fontFamily = (
      @opts.fontFamily or
      atom.config.get('editor.fontFamily') or
      # (Atom doesn't return a default value if there is none)
      # so we use a poor fallback
      "monospace"
    )
    # Atom returns a default for fontSize
    @term.element.style.fontSize = (
      @opts.fontSize or
      atom.config.get('editor.fontSize')
    ) + "px"

  attachEvents: ->
    @resizeToPanel = @resizeToPanel.bind this
    @attachResizeEvents()
    atom.commands.add "atom-workspace", "terminal-plus:paste", => @paste()
    atom.commands.add "atom-workspace", "terminal-plus:copy", => @copy()

  copy: ->
    if  @term._selected  # term.js visual mode selections
      textarea = @term.getCopyTextarea()
      text = @term.grabText(
        @term._selected.x1, @term._selected.x2,
        @term._selected.y1, @term._selected.y2)
    else # fallback to DOM-based selections
      rawText = @term.context.getSelection().toString()
      rawLines = rawText.split(/\r?\n/g)
      lines = rawLines.map (line) ->
        line.replace(/\s/g, " ").trimRight()
      text = lines.join("\n")
    atom.clipboard.write text

  paste: ->
    @input atom.clipboard.read()

  attachResizeEvents: ->
    @on 'focus', @focus
    $('.xterm').on 'resize', @resizeToPanel

  detachResizeEvents: ->
    @off 'focus', @focus
    $('.xterm').off 'resize'

  focus: ->
    @resizeToPanel
    @focusTerm

  focusTerm: ->
    @term.element.focus()
    @term.focus()

  resizeToPanel: ->
    {cols, rows} = @getDimensions()
    return unless cols > 0 and rows > 0
    return unless @term
    return if @term.rows is rows and @term.cols is cols

    @resize cols, rows
    @term.resize cols, rows

  getDimensions: ->
    fakeRow = $("<div><span>&nbsp;</span></div>").css visibility: 'hidden'
    if @term
      @find('.terminal').append fakeRow
      fakeCol = fakeRow.children().first()
      cols = Math.floor (@xterm.width() / fakeCol.width()) or 9
      rows = Math.floor (@xterm.height() / fakeCol.height()) or 16
      @minHeight = fakeCol.height() + 10
      fakeRow.remove()
    else
      cols = Math.floor @width() / 7
      rows = Math.floor @height() / 14

    {cols, rows}
