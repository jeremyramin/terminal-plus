{CompositeDisposable} = require 'atom'

RenameDialog = null

module.exports =
class StatusIcon extends HTMLElement
  active: false

  initialize: (@terminalView) ->
    @classList.add 'pio-terminal-status-icon'

    @icon = document.createElement('i')
    @icon.classList.add 'icon', 'icon-terminal'
    @appendChild(@icon)

    @name = document.createElement('span')
    @name.classList.add 'name'
    @appendChild(@name)

    @dataset.type = @terminalView.constructor?.name

    @addEventListener 'click', ({which, ctrlKey}) =>
      if which is 1
        @terminalView.toggle()
        true
      else if which is 2
        @terminalView.destroy()
        false

    @setupTooltip()

  setupTooltip: ->

    onMouseEnter = (event) =>
      return if event.detail is 'platformio-ide-terminal'
      @updateTooltip()

    @mouseEnterSubscription = dispose: =>
      @removeEventListener('mouseenter', onMouseEnter)
      @mouseEnterSubscription = null

    @addEventListener('mouseenter', onMouseEnter)

  updateTooltip: ->
    @removeTooltip()

    if process = @terminalView.getTerminalTitle()
      @tooltip = atom.tooltips.add this,
        title: process
        html: false
        delay:
          show: 1000
          hide: 100

    @dispatchEvent(new CustomEvent('mouseenter', bubbles: true, detail: 'platformio-ide-terminal'))

  removeTooltip: ->
    @tooltip.dispose() if @tooltip
    @tooltip = null

  destroy: ->
    @removeTooltip()
    @mouseEnterSubscription.dispose() if @mouseEnterSubscription
    @remove()

  activate: ->
    @classList.add 'active'
    @active = true

  isActive: ->
    @classList.contains 'active'

  deactivate: ->
    @classList.remove 'active'
    @active = false

  toggle: ->
    if @active
      @classList.remove 'active'
    else
      @classList.add 'active'
    @active = !@active

  isActive: ->
    return @active

  rename: ->
    RenameDialog ?= require './rename-dialog'
    dialog = new RenameDialog this
    dialog.attach()

  getName: -> @name.textContent.substring(1)

  updateName: (name) ->
    if name isnt @getName()
      name = "&nbsp;" + name if name
      @name.innerHTML = name
      @terminalView.emit 'did-change-title'

module.exports = document.registerElement('pio-terminal-status-icon', prototype: StatusIcon.prototype, extends: 'li')
