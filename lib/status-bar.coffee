{CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

class StatusBar extends View
  attached: false
  container: null

  @content: ->
    @div class: 'terminal-plus inline-block', style: 'width: 100%;', =>
      @div class: 'terminal-plus-status-bar', =>
        @i class: "icon icon-plus", click: 'newTerminalView', outlet: 'plusBtn'
        @ul {
          class: "status-container list-inline",
          tabindex: '-1',
          outlet: 'statusContainer'
        }
        @i {
          class: "icon icon-x",
          style: "color: red;",
          click: 'closeAll',
          outlet: 'closeBtn'
        }

  initialize: ->
    @core = require './core'

    @subscriptions = new CompositeDisposable()

    @subscriptions.add atom.tooltips.add @plusBtn, title: 'New Terminal'
    @subscriptions.add atom.tooltips.add @closeBtn, title: 'Close All'

    @statusContainer.on 'dblclick', (event) =>
      if event.target == event.delegateTarget
        @newTerminalView()

    @registerContextMenu()
    @registerDragDropInterface()
    @registerPaneSubscription()

  destroy: ->
    @destroyContainer()


  ###
  Section: Setup
  ###

  registerContextMenu: ->
    findStatusIcon = (event) ->
      return $(event.target).closest('.status-icon')[0]

    @subscriptions.add atom.commands.add '.terminal-plus-status-bar',
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
        findStatusIcon(event).getTerminal().destroy()
      'terminal-plus:context-hide': (event) ->
        statusIcon = findStatusIcon(event)
        statusIcon.getTerminalView().hide() if statusIcon.isActive()
      'terminal-plus:context-rename': (event) ->
        findStatusIcon(event).getTerminal().promptForRename()

  registerDragDropInterface: ->
    @statusContainer.on 'dragstart', '.status-icon', @onDragStart
    @statusContainer.on 'dragend', '.status-icon', @onDragEnd
    @statusContainer.on 'dragleave', @onDragLeave
    @statusContainer.on 'dragover', @onDragOver
    @statusContainer.on 'drop', @onDrop

  registerPaneSubscription: ->
    @subscriptions.add @paneSubscription = atom.workspace.observePanes (pane) =>
      paneElement = $(atom.views.getView(pane))
      tabBar = paneElement.find('ul')

      tabBar.on 'drop', (event) => @onDropTabBar(event, pane)
      tabBar.on 'dragstart', (event) ->
        return unless event.target.item?.constructor.name is 'TabView'
        event.originalEvent.dataTransfer.setData 'terminal-plus-tab', 'true'
      pane.onDidDestroy -> tabBar.off 'drop', @onDropTabBar


  ###
  Section: Button Handlers
  ###

  closeAll: ->
    @core.closeAll()

  newTerminalView: ->
    @core.newTerminalView()?.toggle()


  ###
  Section: Drag and drop
  ###

  onDragStart: (event) =>
    event.originalEvent.dataTransfer.setData 'terminal-plus-panel', 'true'

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
    unless event.originalEvent.dataTransfer.getData('terminal-plus-panel') is 'true'
      return

    newDropTargetIndex = @getDropTargetIndex(event)
    return unless newDropTargetIndex?
    @removeDropTargetClasses()
    statusIcons = @getStatusIcons()

    if newDropTargetIndex < statusIcons.length
      element = statusIcons.eq(newDropTargetIndex).addClass 'is-drop-target'
      @getPlaceholder().insertBefore(element)
    else
      element = statusIcons.eq(newDropTargetIndex - 1).addClass 'drop-target-is-after'
      @getPlaceholder().insertAfter(element)

  onDrop: (event) =>
    {dataTransfer} = event.originalEvent
    panelEvent = dataTransfer.getData('terminal-plus-panel') is 'true'
    tabEvent = dataTransfer.getData('terminal-plus-tab') is 'true'
    return unless panelEvent or tabEvent

    event.preventDefault()
    event.stopPropagation()

    toIndex = @getDropTargetIndex(event)
    @clearDropTarget()

    if tabEvent
      fromIndex = parseInt(dataTransfer.getData('sortable-index'))
      paneIndex = parseInt(dataTransfer.getData('from-pane-index'))
      pane = atom.workspace.getPanes()[paneIndex]
      view = pane.itemAtIndex(fromIndex)

      pane.removeItem(view, false)
      view.toggleFullscreen()
      fromIndex = @terminalViews.length - 1
    else
      fromIndex = parseInt(dataTransfer.getData('from-index'))
    @updateOrder(fromIndex, toIndex)

  onDropTabBar: (event, pane) =>
    {dataTransfer} = event.originalEvent
    return unless dataTransfer.getData('terminal-plus-panel') is 'true'

    event.preventDefault()
    event.stopPropagation()
    @clearDropTarget()

    fromIndex = parseInt(dataTransfer.getData('from-index'))
    terminal = @terminalViews[fromIndex]
    terminal.css "height", ""
    terminal.getParentView().toggleFullscreen()


  ###
  Section: External
  ###

  addStatusIcon: (icon) ->
    @statusContainer.append icon

  destroyContainer: ->
    if @container
      @container.destroy()
      @container = null

  getContainer: ->
    return @container

  setContainer: (container) ->
    @container = container
    return this


  ###
  Section: Helper Methods
  ###

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

  getStatusIcons: ->
    @statusContainer.children('.status-icon')

  moveIconToIndex: (icon, toIndex) ->
    followingIcon = @getStatusIcons()[toIndex]
    container = @statusContainer[0]
    if followingIcon?
      container.insertBefore(icon, followingIcon)
    else
      container.appendChild(icon)

  updateOrder: (fromIndex, toIndex) ->
    return if fromIndex is toIndex
    toIndex-- if fromIndex < toIndex

    icon = @getStatusIcons().eq(fromIndex).detach()
    @moveIconToIndex icon.get(0), toIndex
    @core.moveTerminal fromIndex, toIndex
    icon.addClass 'inserted'
    icon.one 'webkitAnimationEnd', -> icon.removeClass('inserted')

  clearStatusColor: (event) ->
    $(event.target).closest('.status-icon').css 'color', ''

  setStatusColor: (event) ->
    color = event.type.match(/\w+$/)[0]
    color = atom.config.get("terminal-plus.iconColors.#{color}").toRGBAString()
    $(event.target).closest('.status-icon').css 'color', color

module.exports = new StatusBar()
