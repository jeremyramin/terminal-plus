{$} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'

module.exports =
class StatusIcon extends HTMLElement
  initialize: (@terminal) ->
    @classList.add 'status-icon', 'sortable'

    @icon = document.createElement('i')
    @icon.classList.add 'icon', 'icon-terminal'
    @appendChild(@icon)

    @dataset.type = @terminal.constructor?.name

  close: ->
    @terminal.destroy()
    @destroy()

  destroy: ->
    @subscriptions.dispose()
    @remove()

module.exports = document.registerElement('status-icon', prototype: StatusIcon.prototype, extends: 'li')
