Dialog = require "./dialog"

module.exports =
class RenameDialog extends Dialog
  constructor: (@view) ->
    super
      prompt: "Rename"
      iconClass: "icon-pencil"
      placeholderText: @view.getName()

  onConfirm: (newTitle) ->
    @view.setName newTitle.trim()
    @cancel()
