{$} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'

RenameDialog = null

module.exports =
class StatusIcon extends HTMLElement
  active: false
  process: ''

  initialize: (@terminalView) ->
    @classList.add 'status-icon'

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

  updateTooltip: (process) ->
    return unless process?

    @process = process
    @tooltip = atom.tooltips.add this,
      title: @process
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

  rename: ->
    RenameDialog ?= require './rename-dialog'
    dialog = new RenameDialog(this)
    dialog.attach()

  getName: -> @name.textContent.substring(1)

  updateName: (name) ->
    name = "&nbsp;" + name if name
    @name.innerHTML = name

module.exports = document.registerElement('status-icon', prototype: StatusIcon.prototype, extends: 'li')
