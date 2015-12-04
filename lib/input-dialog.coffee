Dialog = require "./dialog"
os = require "os"

module.exports =
class InputDialog extends Dialog
  constructor: (@terminalView) ->
    @focus = @terminalView.isFocused()
    @terminalView.blur()

    super
      prompt: "Insert Text"
      iconClass: "icon-keyboard"
      stayOpen: true

  onConfirm: (input) ->
    if atom.config.get('terminal-plus.toggles.runInsertedText')
      eol = os.EOL
    else
      eol = ''

    data = "#{input}#{eol}"
    @terminalView.input data
    @cancel()

  cancel: ->
    @terminalView.focus() if @focus
    super()
