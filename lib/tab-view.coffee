{CompositeDisposable, Emitter} = require 'atom'
{$} = require 'atom-space-pen-views'

TerminalView = require './terminal-view'

module.exports =
class TabView extends TerminalView
  opened: false
  lastActiveItem: null
  windowHeight: $(window).height()

  @getFocusedTerminal: ->
    return TerminalView.getFocusedTerminal()

  initialize: ({id, statusBar, path, pwd, terminal}) ->
    super {id, statusBar, path, pwd, terminal}
    @emitter = new Emitter

    @fullscreenBtn = @addButton 'right', @toggleFullscreen, 'screen-normal'
    @inputBtn = @addButton 'left', @promptForInput, 'keyboard'

    @subscriptions.add atom.tooltips.add @fullscreenBtn,
      title: 'Minimize'
    @subscriptions.add atom.tooltips.add @inputBtn,
      title: 'Insert Text'

    @attach()

  attach: (pane, index) ->
    pane ?= atom.workspace.getActivePane()
    index ?= pane.getItems().length

    pane.addItem this, index
    pane.activateItem this

  detach: ->
    atom.workspace.paneForItem(this)?.removeItem(this, true)

  destroy: ({keepTerminal}={}) =>
    @emitter.dispose()
    super(keepTerminal)

  open: =>
    super()
    if pane = atom.workspace.paneForItem(this)
      pane.activateItem this
    @focus()

  hide: =>
    @blur()
    super()

  toggle: ->
    if @isFocused()
      @hide()
    else
      @open()

  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback

  getIconName: ->
    "terminal"

  getTitle: ->
    @terminal.getName() or "Terminal-Plus"

  getPath: ->
    return @terminal.getTitle()

  updateName: (name) ->
    @emitter.emit 'did-change-title', name

  toggleFullscreen: =>
    @detach()
    @destroy keepTerminal: true
    @terminal.enableAnimation()
    panel = new (require './panel-view') {@terminal}
    panel.toggle()
