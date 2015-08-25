{CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

TerminalPlusView = require './view'

window.jQuery = window.$ = $

module.exports =
class StatusBar extends View
  terminalViews: []
  activeIndex: 0

  @content: ->
    @div class: 'terminal-plus status-bar inline-block', =>
      @span class: "icon icon-plus inline-block-tight left", click: 'newTerminalView', outlet: 'plusBtn'
      @ul class: 'list-inline status-container left', outlet: 'statusContainer'
      @span class: "icon icon-x inline-block-tight right red", click: 'exitAll', outlet: 'exitBtn'

  initialize: (state={}) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace',
      'terminal-plus:new': => @newTerminalView()
      'terminal-plus:toggle': => @toggle()
      'terminal-plus:next': => @activeNextTerminalView()
      'terminal-plus:prev': => @activePrevTerminalView()
      'terminal-plus:hide': => @runInCurrentView (i) -> i.close()
      'terminal-plus:destroy': => @runInCurrentView (i) -> i.destroy()

    @registerContextMenu()

    @subscriptions.add atom.tooltips.add @plusBtn, title: 'New Terminal'
    @subscriptions.add atom.tooltips.add @exitBtn, title: 'Exit All'

    @createTerminalView()
    @attach()

    @initializeSorting() if atom.config.get('terminal-plus.toggles.sortableStatus')
    atom.config.onDidChange 'terminal-plus.colors.default', (event) ->
      $('.term-status span').css 'color', event.newValue.toRGBAString()

  registerContextMenu: ->
    @subscriptions.add atom.commands.add '.terminal-plus',
      'terminal-plus:status-red': (event) => @setStatusColor(event)
      'terminal-plus:status-orange': (event) => @setStatusColor(event)
      'terminal-plus:status-yellow': (event) => @setStatusColor(event)
      'terminal-plus:status-green': (event) => @setStatusColor(event)
      'terminal-plus:status-blue': (event) => @setStatusColor(event)
      'terminal-plus:status-purple': (event) => @setStatusColor(event)
      'terminal-plus:status-pink': (event) => @setStatusColor(event)
      'terminal-plus:status-cyan': (event) => @setStatusColor(event)
      'terminal-plus:status-magenta': (event) => @setStatusColor(event)
      'terminal-plus:status-default': (event) => @setStatusColor(event)
      'terminal-plus:context-destroy': (event) -> $(event.target).view.destroy()

  initializeSorting: ->
    require './jquery-sortable'
    @statusContainer.sortable(
      cursor: "move"
      distance: 3
      hoverClass: "term-hover"
      helper: "clone"
      scroll: false
      tolerance: "intersect"
    )
    @statusContainer.disableSelection()
    @statusContainer.on 'sortstart', (event, ui) =>
      ui.item.oldIndex = ui.item.index()
      ui.item.activeTerminal = @terminalViews[@activeIndex]
    @statusContainer.on 'sortupdate', (event, ui) =>
      @moveTerminalView ui.item.oldIndex, ui.item.index(), ui.item.activeTerminal

  createTerminalView: ->
    termStatus = $('<li class="term-status"><span class="icon icon-terminal"></span></li>')
    termStatus.children().css 'color', atom.config.get('terminal-plus.colors.default').toRGBAString()

    options =
      runCommand    : atom.config.get 'terminal-plus.core.autoRunCommand'
      shellOverride : atom.config.get 'terminal-plus.core.shellOverride'
      shellArguments: atom.config.get 'terminal-plus.core.shellArguments'
      cursorBlink   : atom.config.get 'terminal-plus.toggles.cursorBlink'

    terminalPlusView = new TerminalPlusView(options)
    termStatus.view = terminalPlusView
    terminalPlusView.statusIcon = termStatus
    terminalPlusView.statusBar = this
    @terminalViews.push terminalPlusView

    termStatus.children().click () =>
      terminalPlusView.toggle()
    @statusContainer.append termStatus
    return terminalPlusView

  activeNextTerminalView: ->
    @activeTerminalView @activeIndex + 1

  activePrevTerminalView: ->
    @activeTerminalView @activeIndex - 1

  activeTerminalView: (index) ->
    if index >= @terminalViews.length
      index = 0
    if index < 0
      index = @terminalViews.length - 1
    @terminalViews[index].open() if @terminalViews[index]?

  getActiveTerminalView: () ->
    return @terminalViews[@activeIndex]

  runInCurrentView: (call) ->
    v = @getActiveTerminalView()
    if v?
      return call(v)
    return null

  setActiveTerminalView: (terminalView) ->
    @activeIndex = @terminalViews.indexOf terminalView

  removeTerminalView: (terminalView) ->
    index = @terminalViews.indexOf terminalView
    return if index < 0
    @terminalViews.splice index, 1
    @activeIndex-- if index <= @activeIndex and index > 0

  moveTerminalView: (oldIndex, newIndex, activeTerminal) =>
    view = @terminalViews.splice(oldIndex, 1)[0]
    @terminalViews.splice newIndex, 0, view
    @setActiveTerminalView activeTerminal
    console.log @activeIndex

  newTerminalView: ->
    @createTerminalView().toggle()

  attach: () ->
    atom.workspace.addBottomPanel(item: this, priority: 100)

  destroyActiveTerm: ->
    @terminalViews[@activeIndex].destroy() if @terminalViews[@activeIndex]?

  exitAll: ->
    for index in [@terminalViews.length .. 0]
      o = @terminalViews[index]
      if o?
        o.destroy()
    @activeIndex = 0

  destroy: ->
    @subscriptions.dispose()
    for view in @terminalViews
      view.ptyProcess.terminate()
      view.terminal.destroy()
    @detach()

  toggle: ->
    @createTerminalView() unless @terminalViews[@activeIndex]?
    @terminalViews[@activeIndex].toggle()

  setStatusColor: (event) ->
    color = event.type.match(/\w+$/)[0]
    color = atom.config.get("terminal-plus.colors.#{color}").toRGBAString()
    $(event.target).css 'color', color
