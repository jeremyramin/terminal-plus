{CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

PlatformIOTerminalView = require './view'
StatusIcon = require './status-icon'

os = require 'os'
path = require 'path'

module.exports =
class StatusBar extends View
  terminalViews: []
  activeTerminal: null
  returnFocus: null

  @content: ->
    @div class: 'platformio-ide-terminal status-bar', tabindex: -1, =>
      @i class: "icon icon-plus", click: 'newTerminalView', outlet: 'plusBtn'
      @ul class: "list-inline status-container", tabindex: '-1', outlet: 'statusContainer', is: 'space-pen-ul'
      @i class: "icon icon-x", click: 'closeAll', outlet: 'closeBtn'

  initialize: (@statusBarProvider) ->
    @subscriptions = new CompositeDisposable()

    @subscriptions.add atom.commands.add 'atom-workspace',
      'platformio-ide-terminal:focus': => @focusTerminal()
      'platformio-ide-terminal:new': => @newTerminalView()
      'platformio-ide-terminal:toggle': => @toggle()
      'platformio-ide-terminal:next': =>
        return unless @activeTerminal
        return if @activeTerminal.isAnimating()
        @activeTerminal.open() if @activeNextTerminalView()
      'platformio-ide-terminal:prev': =>
        return unless @activeTerminal
        return if @activeTerminal.isAnimating()
        @activeTerminal.open() if @activePrevTerminalView()
      'platformio-ide-terminal:close': => @destroyActiveTerm()
      'platformio-ide-terminal:close-all': => @closeAll()
      'platformio-ide-terminal:rename': => @runInActiveView (i) -> i.rename()
      'platformio-ide-terminal:insert-selected-text': => @runInActiveView (i) -> i.insertSelection('$S')
      'platformio-ide-terminal:insert-text': => @runInActiveView (i) -> i.inputDialog()
      'platformio-ide-terminal:insert-custom-text-1': => @runInActiveView (i) -> i.insertSelection(atom.config.get('platformio-ide-terminal.customTexts.customText1'))
      'platformio-ide-terminal:insert-custom-text-2': => @runInActiveView (i) -> i.insertSelection(atom.config.get('platformio-ide-terminal.customTexts.customText2'))
      'platformio-ide-terminal:insert-custom-text-3': => @runInActiveView (i) -> i.insertSelection(atom.config.get('platformio-ide-terminal.customTexts.customText3'))
      'platformio-ide-terminal:insert-custom-text-4': => @runInActiveView (i) -> i.insertSelection(atom.config.get('platformio-ide-terminal.customTexts.customText4'))
      'platformio-ide-terminal:insert-custom-text-5': => @runInActiveView (i) -> i.insertSelection(atom.config.get('platformio-ide-terminal.customTexts.customText5'))
      'platformio-ide-terminal:insert-custom-text-6': => @runInActiveView (i) -> i.insertSelection(atom.config.get('platformio-ide-terminal.customTexts.customText6'))
      'platformio-ide-terminal:insert-custom-text-7': => @runInActiveView (i) -> i.insertSelection(atom.config.get('platformio-ide-terminal.customTexts.customText7'))
      'platformio-ide-terminal:insert-custom-text-8': => @runInActiveView (i) -> i.insertSelection(atom.config.get('platformio-ide-terminal.customTexts.customText8'))
      'platformio-ide-terminal:fullscreen': => @activeTerminal.maximize()

    @subscriptions.add atom.commands.add '.xterm',
      'platformio-ide-terminal:paste': => @runInActiveView (i) -> i.paste()
      'platformio-ide-terminal:copy': => @runInActiveView (i) -> i.copy()

    @subscriptions.add atom.workspace.onDidChangeActivePaneItem (item) =>
      return unless item?

      if item.constructor.name is "PlatformIOTerminalView"
        setTimeout item.focus, 100
      else if item.constructor.name is "TextEditor"
        mapping = atom.config.get('platformio-ide-terminal.core.mapTerminalsTo')
        return if mapping is 'None'

        switch mapping
          when 'File'
            nextTerminal = @getTerminalById item.getPath(), (view) -> view.getId().filePath
          when 'Folder'
            nextTerminal = @getTerminalById path.dirname(item.getPath()), (view) -> view.getId().folderPath

        prevTerminal = @getActiveTerminalView()
        if prevTerminal != nextTerminal
          if not nextTerminal?
            if item.getTitle() isnt 'untitled'
              if atom.config.get('platformio-ide-terminal.core.mapTerminalsToAutoOpen')
                nextTerminal = @createTerminalView()
          else
            @setActiveTerminalView(nextTerminal)
            nextTerminal.toggle() if prevTerminal?.panel.isVisible()

    @registerContextMenu()

    @subscriptions.add atom.tooltips.add @plusBtn, title: 'New Terminal'
    @subscriptions.add atom.tooltips.add @closeBtn, title: 'Close All'

    @statusContainer.on 'dblclick', (event) =>
      @newTerminalView() unless event.target != event.delegateTarget

    @statusContainer.on 'dragstart', '.pio-terminal-status-icon', @onDragStart
    @statusContainer.on 'dragend', '.pio-terminal-status-icon', @onDragEnd
    @statusContainer.on 'dragleave', @onDragLeave
    @statusContainer.on 'dragover', @onDragOver
    @statusContainer.on 'drop', @onDrop

    handleBlur = =>
      if terminal = PlatformIOTerminalView.getFocusedTerminal()
        @returnFocus = @terminalViewForTerminal(terminal)
        terminal.blur()

    handleFocus = =>
      if @returnFocus
        setTimeout =>
          @returnFocus?.focus(true)
          @returnFocus = null
        , 100

    window.addEventListener 'blur', handleBlur
    @subscriptions.add dispose: ->
      window.removeEventListener 'blur', handleBlur

    window.addEventListener 'focus', handleFocus
    @subscriptions.add dispose: ->
      window.removeEventListener 'focus', handleFocus

    @attach()

  registerContextMenu: ->
    @subscriptions.add atom.commands.add '.platformio-ide-terminal.status-bar',
      'platformio-ide-terminal:status-red': @setStatusColor
      'platformio-ide-terminal:status-orange': @setStatusColor
      'platformio-ide-terminal:status-yellow': @setStatusColor
      'platformio-ide-terminal:status-green': @setStatusColor
      'platformio-ide-terminal:status-blue': @setStatusColor
      'platformio-ide-terminal:status-purple': @setStatusColor
      'platformio-ide-terminal:status-pink': @setStatusColor
      'platformio-ide-terminal:status-cyan': @setStatusColor
      'platformio-ide-terminal:status-magenta': @setStatusColor
      'platformio-ide-terminal:status-default': @clearStatusColor
      'platformio-ide-terminal:context-close': (event) ->
        $(event.target).closest('.pio-terminal-status-icon')[0].terminalView.destroy()
      'platformio-ide-terminal:context-hide': (event) ->
        statusIcon = $(event.target).closest('.pio-terminal-status-icon')[0]
        statusIcon.terminalView.hide() if statusIcon.isActive()
      'platformio-ide-terminal:context-rename': (event) ->
        $(event.target).closest('.pio-terminal-status-icon')[0].rename()

  registerPaneSubscription: ->
    @subscriptions.add @paneSubscription = atom.workspace.observePanes (pane) =>
      paneElement = $(atom.views.getView(pane))
      tabBar = paneElement.find('ul')

      tabBar.on 'drop', (event) => @onDropTabBar(event, pane)
      tabBar.on 'dragstart', (event) ->
        return unless event.target.item?.constructor.name is 'PlatformIOTerminalView'
        event.originalEvent.dataTransfer.setData 'platformio-ide-terminal-tab', 'true'
      pane.onDidDestroy -> tabBar.off 'drop', @onDropTabBar

  createTerminalView: (autoRun) ->
    shell = atom.config.get 'platformio-ide-terminal.core.shell'
    shellArguments = atom.config.get 'platformio-ide-terminal.core.shellArguments'
    args = shellArguments.split(/\s+/g).filter (arg) -> arg
    @createEmptyTerminalView autoRun, shell, args

  createEmptyTerminalView: (autoRun=[], shell = null, args = []) ->
    @registerPaneSubscription() unless @paneSubscription?

    projectFolder = atom.project.getPaths()[0]
    editorPath = atom.workspace.getActiveTextEditor()?.getPath()

    if editorPath?
      editorFolder = path.dirname(editorPath)
      for directory in atom.project.getPaths()
        if editorPath.indexOf(directory) >= 0
          projectFolder = directory

    projectFolder = undefined if projectFolder?.indexOf('atom://') >= 0

    home = if process.platform is 'win32' then process.env.HOMEPATH else process.env.HOME

    switch atom.config.get('platformio-ide-terminal.core.workingDirectory')
      when 'Project' then pwd = projectFolder or editorFolder or home
      when 'Active File' then pwd = editorFolder or projectFolder or home
      else pwd = home

    id = editorPath or projectFolder or home
    id = filePath: id, folderPath: path.dirname(id)

    statusIcon = new StatusIcon()
    platformIOTerminalView = new PlatformIOTerminalView(id, pwd, statusIcon, this, shell, args, autoRun)
    statusIcon.initialize(platformIOTerminalView)

    platformIOTerminalView.attach()

    @terminalViews.push platformIOTerminalView
    @statusContainer.append statusIcon
    return platformIOTerminalView

  activeNextTerminalView: ->
    index = @indexOf(@activeTerminal)
    return false if index < 0
    @activeTerminalView index + 1

  activePrevTerminalView: ->
    index = @indexOf(@activeTerminal)
    return false if index < 0
    @activeTerminalView index - 1

  indexOf: (view) ->
    @terminalViews.indexOf(view)

  activeTerminalView: (index) ->
    return false if @terminalViews.length < 2

    if index >= @terminalViews.length
      index = 0
    if index < 0
      index = @terminalViews.length - 1

    @activeTerminal = @terminalViews[index]
    return true

  getActiveTerminalView: ->
    return @activeTerminal

  focusTerminal: ->
    return unless @activeTerminal?

    if terminal = PlatformIOTerminalView.getFocusedTerminal()
        @activeTerminal.blur()
    else
        @activeTerminal.focusTerminal()

  getTerminalById: (target, selector) ->
    selector ?= (terminal) -> terminal.id

    for index in [0 .. @terminalViews.length]
      terminal = @terminalViews[index]
      if terminal?
        return terminal if selector(terminal) == target

    return null

  terminalViewForTerminal: (terminal) ->
    for index in [0 .. @terminalViews.length]
      terminalView = @terminalViews[index]
      if terminalView?
        return terminalView if terminalView.getTerminal() == terminal

    return null

  runInActiveView: (callback) ->
    view = @getActiveTerminalView()
    if view?
      return callback(view)
    return null

  runNewTerminal: () ->
    @activeTerminal = @createEmptyTerminalView()
    @activeTerminal.toggle()
    return @activeTerminal

  runCommandInNewTerminal: (commands) ->
    @activeTerminal = @createTerminalView(commands)
    @activeTerminal.toggle()

  runInOpenView: (callback) ->
    view = @getActiveTerminalView()
    if view? and view.panel.isVisible()
      return callback(view)
    return null

  setActiveTerminalView: (view) ->
    @activeTerminal = view

  removeTerminalView: (view) ->
    index = @indexOf view
    return if index < 0
    @terminalViews.splice index, 1

    @activateAdjacentTerminal index

  activateAdjacentTerminal: (index=0) ->
    return false unless @terminalViews.length > 0

    index = Math.max(0, index - 1)
    @activeTerminal = @terminalViews[index]

    return true

  newTerminalView: ->
    return if @activeTerminal?.animating

    @activeTerminal = @createTerminalView()
    @activeTerminal.toggle()

  attach: ->
    @statusBarProvider.addLeftTile(item: this, priority: -93)

  destroyActiveTerm: ->
    return unless @activeTerminal?

    index = @indexOf(@activeTerminal)
    @activeTerminal.destroy()
    @activeTerminal = null

    @activateAdjacentTerminal index

  closeAll: =>
    for index in [@terminalViews.length .. 0]
      view = @terminalViews[index]
      if view?
        view.destroy()
    @activeTerminal = null

  destroy: ->
    @subscriptions.dispose()
    for view in @terminalViews
      view.ptyProcess.terminate()
      view.terminal.destroy()
    @detach()

  toggle: ->
    if @terminalViews.length == 0
      @activeTerminal = @createTerminalView()
    else if @activeTerminal == null
      @activeTerminal = @terminalViews[0]
    @activeTerminal.toggle()

  setStatusColor: (event) ->
    color = event.type.match(/\w+$/)[0]
    color = atom.config.get("platformio-ide-terminal.iconColors.#{color}").toRGBAString()
    $(event.target).closest('.pio-terminal-status-icon').css 'color', color

  clearStatusColor: (event) ->
    $(event.target).closest('.pio-terminal-status-icon').css 'color', ''

  onDragStart: (event) =>
    event.originalEvent.dataTransfer.setData 'platformio-ide-terminal-panel', 'true'

    element = $(event.target).closest('.pio-terminal-status-icon')
    element.addClass 'is-dragging'
    event.originalEvent.dataTransfer.setData 'from-index', element.index()

  onDragLeave: (event) =>
    @removePlaceholder()

  onDragEnd: (event) =>
    @clearDropTarget()

  onDragOver: (event) =>
    event.preventDefault()
    event.stopPropagation()
    unless event.originalEvent.dataTransfer.getData('platformio-ide-terminal') is 'true'
      return

    newDropTargetIndex = @getDropTargetIndex(event)
    return unless newDropTargetIndex?
    @removeDropTargetClasses()
    statusIcons = @statusContainer.children '.pio-terminal-status-icon'

    if newDropTargetIndex < statusIcons.length
      element = statusIcons.eq(newDropTargetIndex).addClass 'is-drop-target'
      @getPlaceholder().insertBefore(element)
    else
      element = statusIcons.eq(newDropTargetIndex - 1).addClass 'drop-target-is-after'
      @getPlaceholder().insertAfter(element)

  onDrop: (event) =>
    {dataTransfer} = event.originalEvent
    panelEvent = dataTransfer.getData('platformio-ide-terminal-panel') is 'true'
    tabEvent = dataTransfer.getData('platformio-ide-terminal-tab') is 'true'
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
      view.show()

      view.toggleTabView()
      @terminalViews.push view
      view.open() if view.statusIcon.isActive()
      @statusContainer.append view.statusIcon
      fromIndex = @terminalViews.length - 1
    else
      fromIndex = parseInt(dataTransfer.getData('from-index'))
    @updateOrder(fromIndex, toIndex)

  onDropTabBar: (event, pane) =>
    {dataTransfer} = event.originalEvent
    return unless dataTransfer.getData('platformio-ide-terminal-panel') is 'true'

    event.preventDefault()
    event.stopPropagation()
    @clearDropTarget()

    fromIndex = parseInt(dataTransfer.getData('from-index'))
    view = @terminalViews[fromIndex]
    view.css "height", ""
    view.terminal.element.style.height = ""
    tabBar = $(event.target).closest('.tab-bar')

    view.toggleTabView()
    @removeTerminalView view
    @statusContainer.children().eq(fromIndex).detach()
    view.statusIcon.removeTooltip()

    pane.addItem view, pane.getItems().length
    pane.activateItem view

    view.focus()

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

    statusIcons = @statusContainer.children('.pio-terminal-status-icon')
    element = target.closest('.pio-terminal-status-icon')
    element = statusIcons.last() if element.length is 0

    return 0 unless element.length

    elementCenter = element.offset().left + element.width() / 2

    if event.originalEvent.pageX < elementCenter
      statusIcons.index(element)
    else if element.next('.pio-terminal-status-icon').length > 0
      statusIcons.index(element.next('.pio-terminal-status-icon'))
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
    @statusContainer.children('.pio-terminal-status-icon')

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
