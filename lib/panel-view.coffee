{CompositeDisposable} = require 'atom'
{$} = require 'atom-space-pen-views'

TerminalView = require './terminal-view'
StatusIcon = require './status-icon'

module.exports =
class PanelView extends TerminalView
  animating: false
  opened: false
  windowHeight: atom.getSize().height

  @getFocusedTerminal: ->
    return TerminalView.getFocusedTerminal()

  initialize: ({id, statusBar, path, pwd, terminal}) ->
    super {id, statusBar, path, pwd, terminal}

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

    @prevHeight = atom.config.get('terminal-plus.style.defaultPanelHeight')
    if @prevHeight.indexOf('%') > 0
      percent = Math.abs(Math.min(parseFloat(@prevHeight) / 100.0, 1))
      bottomHeight = $('atom-panel.bottom').children(".terminal-view").height() or 0
      @prevHeight = percent * ($('.item-views').height() + bottomHeight)
    @terminal.height 0

    @setAnimationSpeed()
    @subscriptions.add atom.config.onDidChange 'terminal-plus.style.animationSpeed', @setAnimationSpeed

    @statusIcon = new StatusIcon()
    @statusIcon.initialize(this)
    @statusIcon.attach(statusBar)

    @attachResizeEvents()

  attach: ->
    return if @panel?
    @panel = atom.workspace.addBottomPanel(item: this, visible: false)

  setAnimationSpeed: =>
    @animationSpeed = atom.config.get('terminal-plus.style.animationSpeed')
    @animationSpeed = 100 if @animationSpeed is 0

    @terminal.css 'transition', "height #{0.25 / @animationSpeed}s linear"

  destroy: ({saveTerminal} = {}) =>
    @detachResizeEvents()
    @statusIcon.destroy()

    if saveTerminal
      @terminal = null
      @panel.destroy()
    else if @panel.isVisible()
      @hide()
      @onTransitionEnd => @panel.destroy()
    else
      @panel.destroy()

    super()

  open: =>
    super()

    @onTransitionEnd =>
      if not @opened
        @opened = true
        @terminal.displayView()
        @prevHeight = @nearestRow(@terminal.height())
        @terminal.height(@prevHeight)
      else
        @focus()

    @panel.show()
    @terminal.height 0
    @animating = true
    @terminal.height @prevHeight

  hide: =>
    super()

    @onTransitionEnd =>
      @panel.hide()

    @prevHeight = @terminal.height()
    @terminal.height @prevHeight
    @animating = true
    @terminal.height 0

  toggle: ->
    return if @animating

    if @panel.isVisible()
      @hide()
    else
      @open()

  attachResizeEvents: ->
    @panelDivider.on 'mousedown', @resizeStarted

  detachResizeEvents: ->
    @panelDivider.off 'mousedown'

  onWindowResize: (event) =>
    @terminal.css 'transition', ''
    delta = atom.getSize().height - @windowHeight

    if Math.abs(delta) > @terminal.getRowHeight()
      newHeight = @nearestRow(@terminal.height() + delta)
      console.log newHeight, @prevHeight
      clamped = Math.min(newHeight, @prevHeight)
      console.log clamped
      clamped = Math.max(clamped, @terminal.getRowHeight())
      console.log clamped

      @terminal.height clamped
      @maxHeight += delta
      @windowHeight = atom.getSize().height

      @terminal.recalibrateSize()

    @terminal.css 'transition', "height #{0.25 / @animationSpeed}s linear"

  resizeStarted: =>
    return if @maximized
    @maxHeight = @prevHeight + $('.item-views').height()
    $(document).on('mousemove', @resizePanel)
    $(document).on('mouseup', @resizeStopped)
    @terminal.css 'transition', ''

  resizeStopped: =>
    $(document).off('mousemove', @resizePanel)
    $(document).off('mouseup', @resizeStopped)
    @terminal.css 'transition', "height #{0.25 / @animationSpeed}s linear"

  nearestRow: (value) ->
    rows = value // @terminal.getRowHeight()
    return rows * @terminal.getRowHeight()

  resizePanel: (event) =>
    return @resizeStopped() unless event.which is 1

    mouseY = $(window).height() - event.pageY
    delta = mouseY - $('atom-panel-container.bottom').height()
    return unless Math.abs(delta) > (@terminal.getRowHeight() * 5 / 6)

    nearestRow = @nearestRow(@terminal.height() + delta)
    clamped = Math.max(nearestRow, @terminal.getRowHeight())
    return if clamped > @maxHeight

    @adjustHeight clamped
    @terminal.recalibrateSize()

  onTransitionEnd: (callback) ->
    @terminal.one 'webkitTransitionEnd', =>
      callback()
      @animating = false

  adjustHeight: (height) ->
    @terminal.height height
    @prevHeight = height

  setName: (name) ->
    super(name)
    @statusIcon.updateName(@name)

  toggleFullscreen: =>
    terminal = @terminal
    @destroy({saveTerminal: true})
    tab = new (require './tab-view') {@id, @statusBar, terminal}
    tab.attach()
    terminal.focus()
