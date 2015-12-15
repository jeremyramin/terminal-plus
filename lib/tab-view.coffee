{CompositeDisposable, Emitter} = require 'atom'
{$} = require 'atom-space-pen-views'

TerminalView = require './terminal-view'

module.exports =
class TabView extends TerminalView
  opened: false
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

    @attachWindowEvents()

  attach: (pane, index) ->
    pane ?= atom.workspace.getActivePane()
    index ?= pane.getItems().length

    pane.addItem this, index
    pane.activateItem this

  detach: ->
    pane = atom.workspace.paneForItem(this)
    pane.removeItem(this)

  destroy: ({saveTerminal} = {}) =>
    @emitter.dispose()
    @detach()

    if saveTerminal
      @terminal = null
    super()

  open: =>
    @focus()
    super()

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
    @name or "Terminal-Plus"

  getPath: ->
    return @getProcessTitle()

  setName: (name) ->
    super()
    @emitter.emit 'did-change-title', name

  toggleFullscreen: =>
    terminal = @terminal
    @destroy({saveTerminal: true})
    panel = new (require './panel-view') {@id, @statusBar, terminal}
    panel.attach()
    panel.open()
