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
      'terminal-plus:hide': => @runInActiveView (i) -> i.hide()
      'terminal-plus:close': => @runInActiveView (i) -> i.destroy()

    @subscriptions.add atom.commands.add '.xterm',
      'terminal-plus:paste': => @runInOpenView (i) -> i.paste()
      'terminal-plus:copy': => @runInOpenView (i) -> i.copy()

    @registerContextMenu()

    @subscriptions.add atom.tooltips.add @plusBtn, title: 'New Terminal'
    @subscriptions.add atom.tooltips.add @closeBtn, title: 'Close All'

    @statusContainer.on 'click', '.sortable', ({target, which, ctrlKey}) =>
      statusIcon = $(target).closest('.status-icon')[0]
      if which is 3 or (which is 1 and ctrlKey is true)
        @find('.right-clicked').removeClass('right-clicked')
        statusIcon.classList.add('right-clicked')
        false
      else if which is 1
        statusIcon.terminalView.toggle()
        true
      else if which is 2
        statusIcon.terminalView.destroy()
        false

    @statusContainer.on 'dragstart', '.sortable', @onDragStart
    @statusContainer.on 'dragend', '.sortable', @onDragEnd
    @statusContainer.on 'dragleave', @onDragLeave
    @statusContainer.on 'dragover', @onDragOver
    @statusContainer.on 'drop', @onDrop

    @attach()

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
      'terminal-plus:status-default': (event) => @clearStatusColor(event)
      'terminal-plus:context-close': (event) =>
        $(event.target).closest('.status-icon')[0].terminalView.destroy()
      'terminal-plus:context-hide': (event) ->
        $(event.target).closest('.status-icon')[0].terminalView.hide()

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

  closeAll: ->
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

    element = $(event.target).closest('.sortable')
    element.addClass 'is-dragging'
    event.originalEvent.dataTransfer.setData 'sortable-index', element.index()

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
    sortableObjects = @statusContainer.children(".sortable")

    if newDropTargetIndex < sortableObjects.length
      element = sortableObjects.eq(newDropTargetIndex).addClass 'is-drop-target'
      @getPlaceholder().insertBefore(element)
    else
      element = sortableObjects.eq(newDropTargetIndex - 1).addClass 'drop-target-is-after'
      @getPlaceholder().insertAfter(element)

  onDrop: (event) =>
    {dataTransfer} = event.originalEvent
    return unless dataTransfer.getData('terminal-plus') is 'true'
    event.preventDefault()
    event.stopPropagation()

    fromIndex = parseInt(dataTransfer.getData('sortable-index'))
    toIndex = @getDropTargetIndex(event)
    @clearDropTarget()

    @updateOrder(fromIndex, toIndex)

  clearDropTarget: ->
    element = @find(".is-dragging")
    element.removeClass 'is-dragging'
    @removeDropTargetClasses()
    @removePlaceholder()

  removeDropTargetClasses: ->
    @statusContainer.find('.is-drop-target').removeClass 'is-drop-target'
    @statusContainer.find('.drop-target-is-after').removeClass 'drop-target-is-after'

  getDropTargetIndex: (event) ->
    target = $(event.target)
    return if @isPlaceholder(target)

    sortables = @statusContainer.children('.sortable')
    element = target.closest('.sortable')
    element = sortables.last() if element.length is 0

    return 0 unless element.length

    elementCenter = element.offset().left + element.width() / 2

    if event.originalEvent.pageX < elementCenter
      sortables.index(element)
    else if element.next('.sortable').length > 0
      sortables.index(element.next('.sortable'))
    else
      sortables.index(element) + 1

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
