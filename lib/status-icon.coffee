{CompositeDisposable} = require 'atom'

StatusBar = require './status-bar'

module.exports =
class StatusIcon extends HTMLElement
  active: false

  initialize: (@terminal) ->
    @classList.add 'status-icon'

    @icon = document.createElement('i')
    @icon.classList.add 'icon', 'icon-terminal'
    @appendChild(@icon)

    @name = document.createElement('span')
    @name.classList.add 'name'
    @appendChild(@name)

    @addEventListener 'click', ({which, ctrlKey}) =>
      if which is 1
        @terminal.getParentView().toggle()
        return true
      else if which is 2
        @terminal.getParentView().destroy()
        return false

    @setupTooltip()
    @attach()

  attach: ->
    StatusBar.addStatusIcon(this)

  destroy: ->
    @removeTooltip()
    @mouseEnterSubscription.dispose() if @mouseEnterSubscription
    @remove()


  ###
  Section: Tooltip
  ###

  setupTooltip: ->
    onMouseEnter = (event) =>
      return if event.detail is 'terminal-plus'
      @updateTooltip()

    @mouseEnterSubscription = dispose: =>
      @removeEventListener('mouseenter', onMouseEnter)
      @mouseEnterSubscription = null

    @addEventListener('mouseenter', onMouseEnter)

  updateTooltip: ->
    @removeTooltip()

    if process = @terminal.getTitle()
      @tooltip = atom.tooltips.add this,
        title: process
        html: false
        delay:
          show: 1000
          hide: 100

    @dispatchEvent(new CustomEvent('mouseenter', bubbles: true, detail: 'terminal-plus'))

  removeTooltip: ->
    @tooltip.dispose() if @tooltip
    @tooltip = null


  ###
  Section: Name
  ###

  getName: -> @name.textContent.substring(1)

  setName: (name) ->
    name = "&nbsp;" + name if name
    @name.innerHTML = name


  ###
  Section: Active Status
  ###

  activate: ->
    @classList.add 'active'
    @active = true

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


  ###
  Section: External Methods
  ###

  getTerminal: ->
    return @terminal

  getTerminalView: ->
    return @terminal.getParentView()

  hide: ->
    @style.display = 'none'
    @deactivate()

  show: ->
    @style.display = ''

module.exports = document.registerElement('status-icon', prototype: StatusIcon.prototype, extends: 'li')
