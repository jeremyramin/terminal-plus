{CompositeDisposable} = require 'atom'
{$, View} = require 'atom-space-pen-views'

Terminal = require './terminal'

lastActiveItem = null

module.exports =
class TerminalView extends View
  subscriptions: null
  core: null
  emitter: null
  animating: false

  @content: ({terminal, shellPath, pwd, id}) ->
    @div class: 'terminal-plus', =>
      @div class: 'terminal-view', =>
        @div class: 'panel-divider', outlet: 'panelDivider'
        @div class: 'btn-toolbar', outlet:'toolbar'
        terminal = terminal or new Terminal({shellPath, pwd, id})
        @subview 'terminal', terminal.setParentView(this)

  @getFocusedTerminal: ->
    return Terminal.getFocusedTerminal()

  initialize: ->
    @subscriptions = new CompositeDisposable()
    @attachWindowEvents()

  destroy: (keepTerminal) ->
    @subscriptions.dispose()
    @terminal.destroy() if @terminal and not keepTerminal


  ###
  Section: Window Events
  ###

  attachWindowEvents: ->
    $(window).on 'resize', @onWindowResize

  detachWindowEvents: ->
    $(window).off 'resize', @onWindowResize

  onWindowResize: =>
    @terminal.recalibrateSize()


  ###
  Section: External Methods
  ###

  focus: =>
    @terminal?.focus()
    super()

  blur: =>
    @terminal?.blur()
    super()

  open: =>
    lastActiveItem ?= atom.workspace.getActiveTextEditor()

  hide: (refocus) =>
    if lastActiveItem and refocus
      if pane = atom.workspace.paneForItem(lastActiveItem)
        if activeEditor = atom.workspace.getActiveTextEditor()
          if lastActiveItem != activeEditor
            lastActiveItem = activeEditor
        pane.activateItem lastActiveItem
        atom.views.getView(lastActiveItem).focus()
        lastActiveItem = null

  toggleFocus: ->
    return unless @isVisible()

    if @terminal.isFocused()
      @blur()
      if lastActiveItem
        if pane = atom.workspace.paneForItem(lastActiveItem)
          pane.activateItem lastActiveItem
          atom.views.getView(lastActiveItem).focus()
          lastActiveItem = null
    else
      lastActiveItem ?= atom.workspace.getActiveTextEditor()
      @focus()

  addButton: (side, onClick, icon) ->
    if icon.indexOf('icon-') < 0
      icon = 'icon-' + icon

    button = $("<button/>").addClass("btn inline-block-tight #{side}")
    button.click(onClick)
    button.append $("<span class=\"icon #{icon}\"></span>")

    @toolbar.append button
    button

  isAnimating: ->
    return @animating

  isFocused: ->
    return @terminal.isFocused()

  getTerminal: ->
    return @terminal

  getDisplay: ->
    return @terminal.getDisplay()
