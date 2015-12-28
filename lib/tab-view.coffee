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

  initialize: (options) ->
    super(options)
    @emitter = new Emitter

    @fullscreenBtn = @addButton 'right', @toggleFullscreen, 'screen-normal'
    @inputBtn = @addButton 'left', @promptForInput, 'keyboard'

    @subscriptions.add atom.tooltips.add @fullscreenBtn,
      title: 'Minimize'
    @subscriptions.add atom.tooltips.add @inputBtn,
      title: 'Insert Text'

    @attach()
    @terminal.hideIcon()
    @terminal.displayView()

  destroy: ({keepTerminal}={}) =>
    @emitter.dispose()
    super(keepTerminal)


  ###
  Section: Setup
  ###

  attach: (pane, index) ->
    pane ?= atom.workspace.getActivePane()
    index ?= pane.getItems().length

    pane.addItem this, index

  detach: ->
    atom.workspace.paneForItem(this)?.removeItem(this, true)


  ###
  Section: External Methods
  ###

  open: =>
    super()
    if pane = atom.workspace.paneForItem(this)
      pane.activateItem this
    @focus()

  hide: ({refocus}={}) =>
    refocus ?= true

    @blur()
    super(refocus)

  getIconName: ->
    "terminal"

  getTitle: ->
    @terminal.getName() or "Terminal-Plus"

  getPath: ->
    return @terminal.getTitle()

  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback

  updateName: (name) ->
    @emitter.emit 'did-change-title', name

  toggleFullscreen: =>
    @destroy keepTerminal: true
    @terminal.enableAnimation()
    panel = new (require './panel-view') {@terminal}
    panel.toggle() if @isVisible()
    @detach()

  isVisible: ->
    pane = atom.workspace.paneForItem(this)
    return false unless pane
    return this == pane.getActiveItem()
