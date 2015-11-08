Dialog = require "./dialog"

module.exports =
class RenameDialog extends Dialog
  constructor: (@statusIcon) ->
    super
      prompt: "Rename"
      iconClass: "icon-pencil"
      placeholderText: @statusIcon.getName()

  onConfirm: (newTitle) ->
    @statusIcon.updateName newTitle.trim()
    @cancel()
