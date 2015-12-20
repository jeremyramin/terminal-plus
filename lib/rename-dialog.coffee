Dialog = require "./dialog"

module.exports =
class RenameDialog extends Dialog
  constructor: (@terminal) ->
    super
      prompt: "Rename"
      iconClass: "icon-pencil"
      placeholderText: @terminal.getName()

  onConfirm: (newTitle) ->
    @terminal.setName newTitle.trim()
    @cancel()
