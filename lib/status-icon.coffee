{$} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'

module.exports =
class StatusIcon extends HTMLElement
  active: false

  initialize: (@terminalView) ->
    @classList.add 'status-icon'

    @icon = document.createElement('i')
    @icon.classList.add 'icon', 'icon-terminal'
    @appendChild(@icon)

    @dataset.type = @terminalView.constructor?.name

    @addEventListener 'click', ({which, ctrlKey}) =>
      if which is 1
        @terminalView.toggle()
        true
      else if which is 2
        @terminalView.destroy()
        false

  updateTooltip: (title) ->
    @title = title if title?
    @tooltip = atom.tooltips.add this,
      title: @title
      html: false
      delay:
        show: 500
        hide: 250

  removeTooltip: ->
    @tooltip?.dispose()

  close: ->
    @terminal.destroy()
    @destroy()

  destroy: ->
    @subscriptions.dispose()
    @remove()

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

module.exports = document.registerElement('status-icon', prototype: StatusIcon.prototype, extends: 'li')
