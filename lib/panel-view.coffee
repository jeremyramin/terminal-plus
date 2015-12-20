{CompositeDisposable} = require 'atom'
{$} = require 'atom-space-pen-views'

TerminalView = require './terminal-view'
StatusIcon = require './status-icon'

lastOpenedView = null

defaultHeight = do ->
  height = atom.config.get('terminal-plus.style.defaultPanelHeight')
  if height.indexOf('%') > 0
    percent = Math.abs(Math.min(parseFloat(height) / 100.0, 1))
    bottomHeight = $('atom-panel.bottom').children(".terminal-view").height() or 0
    height = percent * ($('.item-views').height() + bottomHeight)
  return height

module.exports =
class PanelView extends TerminalView
  animating: false
  windowHeight: atom.getSize().height

  @getFocusedTerminal: ->
    return TerminalView.getFocusedTerminal()

  initialize: (options) ->
    super(options)

    @addDefaultButtons()

    @statusIcon = new StatusIcon()
    @statusIcon.initialize(@terminal)
    @updateName(@terminal.getName())

    @attachResizeEvents()
    @attach()

  destroy: ({keepTerminal}={}) =>
    @detachResizeEvents()
    @statusIcon.destroy()

    if @panel.isVisible() and not keepTerminal
      @onTransitionEnd =>
        @panel.destroy()
      @hide()
    else
      @panel.destroy()

    super(keepTerminal)

  ###
  Section: Setup
  ###

  addDefaultButtons: ->
    @closeBtn = @addButton 'right', @destroy, 'x'
    @hideBtn = @addButton 'right', @hide, 'chevron-down'
    @fullscreenBtn = @addButton 'right', @toggleFullscreen, 'screen-full'
    @inputBtn = @addButton 'left', @promptForInput, 'keyboard'

    @subscriptions.add atom.tooltips.add @closeBtn,
      title: 'Close'
    @subscriptions.add atom.tooltips.add @hideBtn,
      title: 'Hide'
    @subscriptions.add atom.tooltips.add @fullscreenBtn,
      title: 'Maximize'
    @subscriptions.add atom.tooltips.add @inputBtn,
      title: 'Insert Text'

  attach: ->
    return if @panel?
    @panel = atom.workspace.addBottomPanel(item: this, visible: false)


  ###
  Section: Resizing
  ###

  attachResizeEvents: ->
    @panelDivider.on 'mousedown', @resizeStarted

  detachResizeEvents: ->
    @panelDivider.off 'mousedown'

  onWindowResize: (event) =>
    @terminal.disableAnimation()
    delta = atom.getSize().height - @windowHeight

    if lines = (delta / @terminal.getRowHeight()|0)
      offset = lines * @terminal.getRowHeight()
      newHeight = @terminal.height() + offset

      if newHeight >= @terminal.getRowHeight()
        @terminal.height newHeight
        @maxHeight += offset
        @windowHeight += offset
      else
        @terminal.height @terminal.getRowHeight()

    @terminal.enableAnimation()
    super()

  resizeStarted: =>
    return if @maximized
    @maxHeight = @terminal.getPrevHeight() + $('.item-views').height()
    $(document).on('mousemove', @resizePanel)
    $(document).on('mouseup', @resizeStopped)
    @terminal.disableAnimation()

  resizeStopped: =>
    $(document).off('mousemove', @resizePanel)
    $(document).off('mouseup', @resizeStopped)
    @terminal.enableAnimation()

  resizePanel: (event) =>
    return @resizeStopped() unless event.which is 1

    mouseY = $(window).height() - event.pageY
    delta = mouseY - $('atom-panel-container.bottom').height()
    return unless Math.abs(delta) > (@terminal.getRowHeight() * 5 / 6)

    nearestRow = @nearestRow(@terminal.height() + delta)
    clamped = Math.max(nearestRow, @terminal.getRowHeight())
    return if clamped > @maxHeight

    @terminal.height clamped
    @terminal.recalibrateSize()


  ###
  Section: External Methods
  ###

  open: =>
    super()
    @statusIcon.activate()

    if lastOpenedView and lastOpenedView != this
      lastOpenedView.hide({refocus: false})
    lastOpenedView = this

    @onTransitionEnd =>
      if @terminal.displayView()
        height = @nearestRow(@terminal.height())
        @terminal.height(height)
      @focus()

    @panel.show()
    @terminal.height 0
    @animating = true
    @terminal.height @terminal.getPrevHeight() or defaultHeight

  hide: ({refocus}={})=>
    refocus ?= true
    @statusIcon.deactivate()

    @onTransitionEnd =>
      @panel.hide()
      super(refocus)

    @terminal.height @terminal.getPrevHeight()
    @animating = true
    @terminal.height 0

  updateName: (name) ->
    @statusIcon.setName(name)

  toggleFullscreen: =>
    @destroy keepTerminal: true
    @terminal.clearHeight().disableAnimation()
    tabView = new (require './tab-view') {@terminal}
    tabView.toggle()
    @remove()

  isVisible: ->
    @panel.isVisible()


  ###
  Section: Helper Methods
  ###

  nearestRow: (value) ->
    rowHeight = @terminal.getRowHeight()
    return rowHeight * Math.round(value / rowHeight)

  onTransitionEnd: (callback) ->
    @terminal.one 'webkitTransitionEnd', =>
      callback()
      @animating = false
