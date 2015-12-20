{CompositeDisposable} = require 'atom'

PanelView = null
TabView = null

Path = require 'path'

class Core
  subscriptions: null
  activeTerminal: null
  terminals: []
  returnFocus: false

  constructor: ->
    @subscriptions = new CompositeDisposable()

    @registerCommands()
    @registerActiveItemSubscription()
    @registerWindowEvents()

  destroy: ->
    @subscriptions.dispose()
    for terminal in @terminals
      terminal.destroy()

  ###
  Section: Setup
  ###

  registerCommands: ->
    @subscriptions.add atom.commands.add 'atom-workspace',
      'terminal-plus:new': => @newTerminalView()?.toggle()

      'terminal-plus:toggle': => @toggle()

      'terminal-plus:next': =>
        @activeTerminal.open() if @activateNextTerminal()
      'terminal-plus:prev': =>
        @activeTerminal.open() if @activatePrevTerminal()

      'terminal-plus:close': => @destroyActiveTerminal()
      'terminal-plus:close-all': => @closeAll()

      'terminal-plus:rename': =>
        @runInActiveTerminal (i) -> i.promptForRename()
      'terminal-plus:insert-selected-text': =>
        @runInActiveTerminal (i) -> i.insertSelection()
      'terminal-plus:insert-text': =>
        @runInActiveTerminal (i) -> i.promptForInput()
      'terminal-plus:toggle-focus': =>
        @runInActiveTerminal (i) -> i.toggleFocus()
      'terminal-plus:toggle-full-screen': =>
        @runInActiveTerminal (i) -> i.toggleFullscreen()

    @subscriptions.add atom.commands.add '.xterm',
      'terminal-plus:paste': =>
        @runInActiveTerminal (i) -> i.paste()
      'terminal-plus:copy': =>
        @runInActiveTerminal (i) -> i.copy()

  registerActiveItemSubscription: ->
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem (item) =>
      return unless item?

      if item.constructor.name is "TabView"
        setTimeout item.focus, 100
      else if item.constructor.name is "TextEditor"
        mapping = atom.config.get('terminal-plus.core.mapTerminalsTo')
        return if mapping is 'None'

        switch mapping
          when 'File'
            nextTerminal = @findFirstTerminal (terminal) ->
              item.getPath() == terminal.getId().filePath
          when 'Folder'
            nextTerminal = @findFirstTerminal (terminal) ->
              Path.dirname(item.getPath()) == terminal.getId().folderPath

        prevTerminal = @getActiveTerminal()
        if prevTerminal != nextTerminal
          if not nextTerminal?
            if item.getTitle() isnt 'untitled'
              if atom.config.get('terminal-plus.core.mapTerminalsToAutoOpen')
                nextTerminal = @createTerminalView().getTerminal()
          else
            @setActiveTerminal(nextTerminal)
            if prevTerminal.getParentView()?.panel.isVisible()
              nextTerminal.getParentView().toggle()

  registerWindowEvents: ->
    handleBlur = =>
      if @activeTerminal?.isFocused()
        @returnFocus = true
        @activeTerminal.getParentView().blur()

    handleFocus = =>
      if @returnFocus
        setTimeout =>
          @activeTerminal.focus()
          @returnFocus = false
        , 100

    window.addEventListener 'blur', handleBlur
    @subscriptions.add dispose: ->
      window.removeEventListener 'blur', handleBlur

    window.addEventListener 'focus', handleFocus
    @subscriptions.add dispose: ->
      window.removeEventListener 'focus', handleFocus

  ###
  Section: Command Handling
  ###

  activateNextTerminal: ->
    return false if (not @activeTerminal) or @activeTerminal.isAnimating()

    index = @terminals.indexOf(@activeTerminal)
    return false if index < 0
    @activateTerminalAtIndex index + 1

  activatePrevTerminal: ->
    return false if (not @activeTerminal) or @activeTerminal.isAnimating()

    index = @terminals.indexOf(@activeTerminal)
    return false if index < 0
    @activateTerminalAtIndex index - 1

  closeAll: =>
    panels = @getPanelViews()
    @terminals = @getTabViews()

    for panel in panels
      panel.getParentView().destroy()

    @activeTerminal = @terminals[0]

  destroyActiveTerminal: ->
    return unless @activeTerminal?

    index = @terminals.indexOf(@activeTerminal)
    @removeTerminalAt(index)
    @activeTerminal.getParentView().destroy()
    @activeTerminal = null

    @activateAdjacentTerminal index

  newTerminalView: =>
    PanelView ?= require './panel-view'
    TabView ?= require './tab-view'

    return null if @activeTerminal and @activeTerminal.isAnimating()

    terminalView = @createTerminalView()
    @terminals.push terminalView.getTerminal()
    return terminalView

  runInActiveTerminal: (callback) ->
    terminal = @getActiveTerminal()
    if terminal?
      return callback(terminal)
    return null

  toggle: ->
    return if @activeTerminal and @activeTerminal.isAnimating()

    if @terminals.length == 0
      @activeTerminal = @newTerminalView().getTerminal()
    else if @activeTerminal == null
      @activeTerminal = @terminals[0]
    @activeTerminal.toggle()


  ###
  Section: External Methods
  ###

  getActiveTerminal: ->
    return @activeTerminal

  getActiveTerminalView: ->
    return @activeTerminal.getParentView()

  getTerminals: ->
    return @terminals

  removeTerminal: (terminal) ->
    index = @terminals.indexOf terminal
    return if index < 0
    @terminals.splice index, 1

    if terminal == @activeTerminal
      unless @activateAdjacentTerminal()
        @activeTerminal = null

  removeTerminalAt: (index) ->
    return if index < 0 or index > @terminals.length
    return @terminals.splice(index, 1)[0]

  removeTerminalView: (view) ->
    @removeTerminal view.getTerminal()

  setActiveTerminal: (terminal) ->
    @activeTerminal = terminal

  setActiveTerminalView: (view) ->
    @setActiveTerminal view.getTerminal()

  terminalAt: (index) ->
    return @terminals[index]

  moveTerminal: (fromIndex, toIndex) =>
    fromIndex = Math.max(0, fromIndex)
    toIndex = Math.min(toIndex, @terminals.length)

    terminal = @terminals.splice(fromIndex, 1)[0]
    @terminals.splice toIndex, 0, terminal


  ###
  Section: Helper Methods
  ###

  activateAdjacentTerminal: (index = 0) ->
    return false unless @terminals.length > 0

    index = Math.max(0, index - 1)
    @activeTerminal = @terminals[index]

  activateTerminalAtIndex: (index) ->
    return false if @terminals.length < 2

    if index >= @terminals.length
      index = 0
    if index < 0
      index = @terminals.length - 1

    @activeTerminal = @terminals[index]
    return true

  createTerminalView: ->
    projectFolder = atom.project.getPaths()[0]
    editorPath = atom.workspace.getActiveTextEditor()?.getPath()

    if editorPath?
      editorFolder = Path.dirname(editorPath)
      for directory in atom.project.getPaths()
        if editorPath.indexOf(directory) >= 0
          projectFolder = directory

    projectFolder = undefined if projectFolder?.indexOf('atom://') >= 0

    home = if process.platform is 'win32' then process.env.HOMEPATH else process.env.HOME

    switch atom.config.get('terminal-plus.core.workingDirectory')
      when 'Project' then pwd = projectFolder or editorFolder or home
      when 'Active File' then pwd = editorFolder or projectFolder or home
      else pwd = home

    id = editorPath or projectFolder or home
    id = filePath: id, folderPath: Path.dirname(id)

    shellPath = atom.config.get 'terminal-plus.core.shell'

    return new PanelView {
      id, pwd, shellPath
    }

  findFirstTerminal: (filter) ->
    matches = @terminals.filter filter
    return matches[0]

  iconAtIndex: (index) ->
    @getStatusIcons().eq(index)

  getPanelViews: ->
    @terminals.filter (terminal) -> terminal.isPanelView()

  getTabViews: ->
    @terminals.filter (terminal) -> terminal.isTabView()

module.exports = exports = new Core()
