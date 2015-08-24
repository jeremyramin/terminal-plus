{$, View} = require 'atom-space-pen-views'
TerminalPlusView = require './view'
{CompositeDisposable} = require 'atom'

module.exports =
class StatusBar extends View
  terminalViews: []
  activeIndex: 0

  @content: ->
    @div class: 'terminal-plus status-bar inline-block', =>
      @span class: "icon icon-plus inline-block-tight left", click: 'newTerminalView', outlet: 'plusBtn'
      @ul class: 'list-inline status-container left', outlet: 'termStatusContainer'
      @span class: "icon icon-x inline-block-tight right", click: 'exitAll', outlet: 'exitBtn'

  initialize: (state={}) ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace',
      'terminal-plus:new': => @newTerminalView()
      'terminal-plus:toggle': => @toggle()
      'terminal-plus:next': => @activeNextTerminalView()
      'terminal-plus:prev': => @activePrevTerminalView()
      'terminal-plus:hide': => @runInCurrentView (i) -> i.close()
      'terminal-plus:destroy': =>  @runInCurrentView (i) -> i.destroy()
      'terminal-plus:reload-config': => @runInCurrentView (i) ->
        i.clear()
        i.reloadSettings()
        i.clear()
      'terminal-plus:open-config': => @runInCurrentView (i) ->
        i.showSettings()

    @subscriptions.add atom.tooltips.add @plusBtn, title: 'New Terminal'
    @subscriptions.add atom.tooltips.add @exitBtn, title: 'Exit All'

    @createTerminalView()
    @attach()

  createTerminalView: ->
    termStatus = $('<li class="term-status"><span class="icon icon-terminal"></span></li>')

    options =
      runCommand    : atom.config.get 'terminal-plus.core.autoRunCommand'
      shellOverride : atom.config.get 'terminal-plus.core.shellOverride'
      shellArguments: atom.config.get 'terminal-plus.core.shellArguments'
      cursorBlink   : atom.config.get 'terminal-plus.style.toggles.cursorBlink'

    terminalPlusView = new TerminalPlusView(options)
    terminalPlusView.statusIcon = termStatus
    termStatus.terminalView = terminalPlusView
    terminalPlusView.statusBar = this
    @terminalViews.push terminalPlusView
    termStatus.click () =>
      terminalPlusView.toggle()
    @termStatusContainer.append termStatus
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
    @terminalViews[index] and @terminalViews[index].open()

  getActiveTerminalView: () ->
    return @terminalViews[@activeIndex]

  runInCurrentView: (call) ->
    v = @getForcedActiveTerminalView()
    if v?
      return call(v)
    return null

  getForcedActiveTerminalView: () ->
    if @getActiveTerminalView() != null && @getActiveTerminalView() != undefined
      return @getActiveTerminalView()
    ret = @activeTerminalView(0)
    @toggle()
    return ret

  setActiveTerminalView: (terminalView) ->
    @activeIndex = @terminalViews.indexOf terminalView

  removeTerminalView: (terminalView) ->
    index = @terminalViews.indexOf terminalView
    index >=0 and @terminalViews.splice index, 1

  newTerminalView: ->
    @createTerminalView().toggle()

  attach: () ->
    atom.workspace.addBottomPanel(item: this, priority: 100)

  destroyActiveTerm: ->
     @terminalViews[@activeIndex]?.destroy()

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
