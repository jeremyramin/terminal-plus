{$} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'

module.exports =
class StatusIcon extends HTMLElement
  initialize: (@terminalView) ->
    @classList.add 'status-icon', 'sortable'

    @icon = document.createElement('i')
    @icon.classList.add 'icon', 'icon-terminal'
    @appendChild(@icon)

    @dataset.type = @terminalView.constructor?.name

    @terminalView.ptyProcess.on 'terminal-plus:title', (title) =>
      @updateTooltip(title)

    @terminalView.ptyProcess.on 'terminal-plus:clear-title', =>
      @removeTooltip()

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

module.exports = document.registerElement('status-icon', prototype: StatusIcon.prototype, extends: 'li')
