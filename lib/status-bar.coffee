{CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

TerminalPlusView = require './view'
StatusIcon = require './status-icon'

module.exports =
class StatusBar extends View
  terminalViews: []
  activeIndex: 0

  @content: ->
    @div class: 'terminal-plus status-bar', tabindex: -1, =>
      @i class: "icon icon-plus", click: 'newTerminalView', outlet: 'plusBtn'
      @ul class: "list-inline status-container", tabindex: '-1', outlet: 'statusContainer', is: 'space-pen-ul'
      @i class: "icon icon-x", click: 'closeAll', outlet: 'closeBtn'

  initialize: () ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace',
      'terminal-plus:new': => @newTerminalView()
      'terminal-plus:toggle': => @toggle()
      'terminal-plus:next': => @activeNextTerminalView()
      'terminal-plus:prev': => @activePrevTerminalView()
      'terminal-plus:close': => @runInActiveView (i) -> i.destroy()
      'terminal-plus:insert-selected-text': => @runInActiveView (i) -> i.insertSelection()

    @subscriptions.add atom.commands.add '.xterm',
      'terminal-plus:paste': => @runInOpenView (i) -> i.paste()
      'terminal-plus:copy': => @runInOpenView (i) -> i.copy()

    @registerCommands()

    @subscriptions.add atom.tooltips.add @plusBtn, title: 'New Terminal'
    @subscriptions.add atom.tooltips.add @closeBtn, title: 'Close All'

    @statusContainer.on 'dblclick', => @newTerminalView()

    @statusContainer.on 'dragstart', '.status-icon', @onDragStart
    @statusContainer.on 'dragend', '.status-icon', @onDragEnd
    @statusContainer.on 'dragleave', @onDragLeave
    @statusContainer.on 'dragover', @onDragOver
    @statusContainer.on 'drop', @onDrop

    @attach()

  registerCommands: ->
    @subscriptions.add atom.commands.add '.terminal-plus',
      'terminal-plus:status-red': @setStatusColor
      'terminal-plus:status-orange': @setStatusColor
      'terminal-plus:status-yellow': @setStatusColor
      'terminal-plus:status-green': @setStatusColor
      'terminal-plus:status-blue': @setStatusColor
      'terminal-plus:status-purple': @setStatusColor
      'terminal-plus:status-pink': @setStatusColor
      'terminal-plus:status-cyan': @setStatusColor
      'terminal-plus:status-magenta': @setStatusColor
      'terminal-plus:status-default': @clearStatusColor
      'terminal-plus:context-close': (event) ->
        $(event.target).closest('.status-icon')[0].terminalView.destroy()
      'terminal-plus:context-hide': (event) ->
        statusIcon = $(event.target).closest('.status-icon')[0]
        statusIcon.terminalView.hide() if statusIcon.isActive()
      'terminal-plus:context-rename': (event) ->
        $(event.target).closest('.status-icon')[0].rename()
      'terminal-plus:close-all': @closeAll

  createTerminalView: ->
    statusIcon = new StatusIcon()

    terminalPlusView = new TerminalPlusView()
    statusIcon.initialize(terminalPlusView)

    terminalPlusView.statusBar = this
    terminalPlusView.statusIcon = statusIcon
    terminalPlusView.panel = atom.workspace.addBottomPanel(item: terminalPlusView, visible: false)

    @terminalViews.push terminalPlusView
    @statusContainer.append statusIcon
    return terminalPlusView

  activeNextTerminalView: ->
    @activeTerminalView @activeIndex + 1

  activePrevTerminalView: ->
    @activeTerminalView @activeIndex - 1

  activeTerminalView: (index) ->
    return unless @terminalViews.length > 1

    if index >= @terminalViews.length
      index = 0
    if index < 0
      index = @terminalViews.length - 1

    @terminalViews[index].open()

  getActiveTerminalView: () ->
    return @terminalViews[@activeIndex]

  runInActiveView: (callback) ->
    view = @getActiveTerminalView()
    if view?
      return callback(view)
    return null

  runInOpenView: (callback) ->
    view = @getActiveTerminalView()
    if view? and view.panel.isVisible()
      return callback(view)
    return null

  setActiveTerminalView: (terminalView) ->
    @activeIndex = @terminalViews.indexOf terminalView

  removeTerminalView: (terminalView) ->
    index = @terminalViews.indexOf terminalView
    return if index < 0
    @terminalViews.splice index, 1
    @activeIndex-- if index <= @activeIndex and @activeIndex > 0

  newTerminalView: ->
    @createTerminalView().toggle()

  attach: () ->
    atom.workspace.addBottomPanel(item: this, priority: 100)

  destroyActiveTerm: ->
    @terminalViews[@activeIndex].destroy() if @terminalViews[@activeIndex]?

  closeAll: =>
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
    $(event.target).closest('.status-icon').css 'color', color

  clearStatusColor: (event) ->
    $(event.target).closest('.status-icon').css 'color', ''

  onDragStart: (event) =>
    event.originalEvent.dataTransfer.setData 'terminal-plus', 'true'

    element = $(event.target).closest('.status-icon')
    element.addClass 'is-dragging'
    event.originalEvent.dataTransfer.setData 'from-index', element.index()

  onDragLeave: (event) =>
    @removePlaceholder()

  onDragEnd: (event) =>
    @clearDropTarget()

  onDragOver: (event) =>
    event.preventDefault()
    event.stopPropagation()
    unless event.originalEvent.dataTransfer.getData('terminal-plus') is 'true'
      return

    newDropTargetIndex = @getDropTargetIndex(event)
    return unless newDropTargetIndex?
    @removeDropTargetClasses()
    statusIcons = @statusContainer.children '.status-icon'

    if newDropTargetIndex < statusIcons.length
      element = statusIcons.eq(newDropTargetIndex).addClass 'is-drop-target'
      @getPlaceholder().insertBefore(element)
    else
      element = statusIcons.eq(newDropTargetIndex - 1).addClass 'drop-target-is-after'
      @getPlaceholder().insertAfter(element)

  onDrop: (event) =>
    {dataTransfer} = event.originalEvent
    return unless dataTransfer.getData('terminal-plus') is 'true'
    event.preventDefault()
    event.stopPropagation()

    fromIndex = parseInt(dataTransfer.getData('from-index'))
    toIndex = @getDropTargetIndex(event)
    @clearDropTarget()

    @updateOrder(fromIndex, toIndex)

  clearDropTarget: ->
    element = @find('.is-dragging')
    element.removeClass 'is-dragging'
    @removeDropTargetClasses()
    @removePlaceholder()

  removeDropTargetClasses: ->
    @statusContainer.find('.is-drop-target').removeClass 'is-drop-target'
    @statusContainer.find('.drop-target-is-after').removeClass 'drop-target-is-after'

  getDropTargetIndex: (event) ->
    target = $(event.target)
    return if @isPlaceholder(target)

    statusIcons = @statusContainer.children('.status-icon')
    element = target.closest('.status-icon')
    element = statusIcons.last() if element.length is 0

    return 0 unless element.length

    elementCenter = element.offset().left + element.width() / 2

    if event.originalEvent.pageX < elementCenter
      statusIcons.index(element)
    else if element.next('.status-icon').length > 0
      statusIcons.index(element.next('.status-icon'))
    else
      statusIcons.index(element) + 1

  getPlaceholder: ->
    @placeholderEl ?= $('<li class="placeholder"></li>')

  removePlaceholder: ->
    @placeholderEl?.remove()
    @placeholderEl = null

  isPlaceholder: (element) ->
    element.is('.placeholder')

  iconAtIndex: (index) ->
    @getStatusIcons().eq(index)

  getStatusIcons: ->
    @statusContainer.children('.status-icon')

  moveIconToIndex: (icon, toIndex) ->
    followingIcon = @getStatusIcons()[toIndex]
    container = @statusContainer[0]
    if followingIcon?
      container.insertBefore(icon, followingIcon)
    else
      container.appendChild(icon)

  moveTerminalView: (fromIndex, toIndex) =>
    activeTerminal = @getActiveTerminalView()
    view = @terminalViews.splice(fromIndex, 1)[0]
    @terminalViews.splice toIndex, 0, view
    @setActiveTerminalView activeTerminal

  updateOrder: (fromIndex, toIndex) ->
    return if fromIndex is toIndex
    toIndex-- if fromIndex < toIndex

    icon = @getStatusIcons().eq(fromIndex).detach()
    @moveIconToIndex icon.get(0), toIndex
    @moveTerminalView fromIndex, toIndex
    icon.addClass 'inserted'
    icon.one 'webkitAnimationEnd', -> icon.removeClass('inserted')
