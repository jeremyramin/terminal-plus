{CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

Terminal = require './terminal'
InputDialog = null
RenameDialog = null

lastOpenedView = null
lastActiveElement = null

module.exports =
class TerminalView extends View
  subscriptions: null
  emitter: null
  name: null

  @content: ({terminal, shellPath, pwd}) ->
    @div class: 'terminal-plus terminal-view', =>
      @div class: 'panel-divider', outlet: 'panelDivider'
      @div class: 'btn-toolbar', outlet:'toolbar'
      terminal = terminal or new Terminal({shellPath, pwd})
      @subview 'terminal', terminal.setParentView(this)

  @getFocusedTerminal: ->
    return Terminal.getFocusedTerminal()

  initialize: ({@id, @statusBar}) ->
    @subscriptions = new CompositeDisposable
    @attachWindowEvents()

  getId: ->
    return @id

  destroy: ->
    @subscriptions.dispose()
    @statusBar.removeTerminalView this
    @terminal.destroy() if @terminal

  copy: ->
    if @terminal.display._selected
      textarea = @terminal.display.getCopyTextarea()
      text = @terminal.display.grabText(
        @terminal.display._selected.x1, @terminal.display._selected.x2,
        @terminal.display._selected.y1, @terminal.display._selected.y2)
    else
      rawText = @terminal.display.context.getSelection().toString()
      rawLines = rawText.split(/\r?\n/g)
      lines = rawLines.map (line) ->
        line.replace(/\s/g, " ").trimRight()
      text = lines.join("\n")
    atom.clipboard.write text

  paste: ->
    @terminal.input atom.clipboard.read()

  insertSelection: ->
    return unless editor = atom.workspace.getActiveTextEditor()
    runCommand = atom.config.get('terminal-plus.toggles.runInsertedText')

    if selection = editor.getSelectedText()
      @terminal.stopScrolling()
      @terminal.input "#{selection}#{if runCommand then os.EOL else ''}"
    else if cursor = editor.getCursorBufferPosition()
      line = editor.lineTextForBufferRow(cursor.row)
      @terminal.stopScrolling()
      @input "#{line}#{if runCommand then os.EOL else ''}"
      editor.moveDown(1);

  focus: =>
    @terminal?.focus()
    @statusBar.setActiveTerminalView(this)
    super()

  blur: =>
    @terminal?.blur()
    super()

  addButton: (side, onClick, icon) ->
    if icon.indexOf('icon-') < 0
      icon = 'icon-' + icon

    button = $("<button/>").addClass("btn inline-block-tight #{side}")
    button.click(onClick)
    button.append $("<span class=\"icon #{icon}\"></span>")

    @toolbar.append button
    button

  isFocused: ->
    return TerminalView.getFocusedTerminal() == @terminal

  open: ->
    lastActiveElement ?= $(document.activeElement)

    if lastOpenedView and lastOpenedView != this
      lastOpenedView.hide()

    lastOpenedView = this
    @statusBar.setActiveTerminalView this
    @statusIcon.activate()

  hide: ->
    lastOpenedView = null
    lastActiveElement.focus()
    @statusIcon.deactivate()

  attachWindowEvents: ->
    $(window).on 'resize', @onWindowResize

  detachWindowEvents: ->
    $(window).off 'resize', @onWindowResize

  onWindowResize: =>
    @terminal.recalibrateSize()

  promptForRename: =>
    RenameDialog ?= require './rename-dialog'
    dialog = new RenameDialog this
    dialog.attach()

  promptForInput: =>
    InputDialog ?= require('./input-dialog')
    dialog = new InputDialog this
    @blurTerminal()
    dialog.attach()

  setName: (name) ->
    if @name != name
      @name = name

  getName: ->
    return @name

  getTerminal: ->
    return @terminal

  getDisplay: ->
    return @terminal.getDisplay()

  getProcessTitle: ->
    return @terminal.getTitle()
