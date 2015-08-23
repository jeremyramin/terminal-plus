{$, View} = require 'atom-space-pen-views'
TerminalPlusView = require './view'

module.exports =
class TerminalPlusPanel extends View
  @content: ->
    @div class: 'terminal-plus-panel inline-block', =>
      @span outlet: 'termStatusContainer', =>
        @span click: 'newTermClick', class: "icon icon-plus"

  commandViews: []
  activeIndex: 0
  initialize: (serializeState) ->

    getSelectedText = () ->
      text = ''
      if window.getSelection
        text = window.getSelection().toString()
      else if document.selection and document.selection.type != "Control"
        text = document.selection.createRange().text
      return text

    atom.commands.add 'atom-workspace',
      'terminal-plus:new': => @newTermClick()
      'terminal-plus:toggle': => @toggle()
      'terminal-plus:next': => @activeNextCommandView()
      'terminal-plus:prev': => @activePrevCommandView()
      'terminal-plus:hide': => @runInCurrentView (i) -> i.close()
      'terminal-plus:destroy': =>  @runInCurrentView (i) -> i.destroy()
      'terminal-plus:reload-config': => @runInCurrentView (i) ->
        i.clear()
        i.reloadSettings()
        i.clear()
      'terminal-plus:open-config': => @runInCurrentView (i) ->
        i.showSettings()

    @createCommandView()
    @attach()

  createCommandView: ->
    termStatus = $('<span class="icon icon-terminal"></span>')

    options =
      runCommand    : atom.config.get 'terminal-plus.core.autoRunCommand'
      shellOverride : atom.config.get 'terminal-plus.core.shellOverride'
      shellArguments: atom.config.get 'terminal-plus.core.shellArguments'
      cursorBlink   : atom.config.get 'terminal-plus.style.toggles.cursorBlink'

    terminalPlusView = new TerminalPlusView(options)
    terminalPlusView.statusIcon = termStatus
    terminalPlusView.statusView = this
    @commandViews.push terminalPlusView
    termStatus.click () =>
      terminalPlusView.toggle()
    @termStatusContainer.append termStatus
    return terminalPlusView

  activeNextCommandView: ->
    @activeCommandView @activeIndex + 1

  activePrevCommandView: ->
    @activeCommandView @activeIndex - 1

  activeCommandView: (index) ->
    if index >= @commandViews.length
      index = 0
    if index < 0
      index = @commandViews.length - 1
    @updateStatusBar @commandViews[index]
    @commandViews[index] and @commandViews[index].open()

  getActiveCommandView: () ->
    return @commandViews[@activeIndex]

  runInCurrentView: (call) ->
    v = @getForcedActiveCommandView()
    if v?
      return call(v)
    return null

  getForcedActiveCommandView: () ->
    if @getActiveCommandView() != null && @getActiveCommandView() != undefined
      return @getActiveCommandView()
    ret = @activeCommandView(0)
    @toggle()
    return ret

  setActiveCommandView: (commandView) ->
    @activeIndex = @commandViews.indexOf commandView

  removeCommandView: (commandView) ->
    index = @commandViews.indexOf commandView
    index >=0 and @commandViews.splice index, 1

  newTermClick: ->
    @createCommandView().toggle()

  attach: () ->
    # console.log 'panel attached!'
    atom.workspace.addBottomPanel(item: this, priority: 100)

  destroyActiveTerm: ->
     @commandViews[@activeIndex]?.destroy()

  closeAll: ->
    for index in [@commandViews.length .. 0]
      o = @commandViews[index]
      if o?
        o.close()

  # Tear down any state and detach
  destroy: ->
    for view in @commandViews
      view.ptyProcess.terminate()
      view.terminal.destroy()
    @detach()

  toggle: ->
    @createCommandView() unless @commandViews[@activeIndex]?
    @commandViews[@activeIndex].toggle()
